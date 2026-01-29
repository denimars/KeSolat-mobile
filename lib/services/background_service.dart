import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import 'notification_service.dart';
import 'stop_flag_service.dart';
import 'audio_service.dart';

/// Background service using AlarmManager for battery-efficient prayer time alarms.
/// Instead of running continuously, it schedules exact alarms for each prayer time.
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const int _fajrAlarmId = 1;
  static const int _dhuhrAlarmId = 2;
  static const int _asrAlarmId = 3;
  static const int _maghribAlarmId = 4;
  static const int _ishaAlarmId = 5;
  static const int _dailyRescheduleAlarmId = 100;

  bool _isInitialized = false;

  /// Initialize the AlarmManager
  Future<void> initialize() async {
    if (_isInitialized) return;
    await AndroidAlarmManager.initialize();
    _isInitialized = true;
  }

  /// Schedule alarms for all prayer times today
  Future<void> scheduleAllPrayerAlarms() async {
    final prefs = await SharedPreferences.getInstance();

    final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;
    if (!adhanEnabled) {
      await cancelAllAlarms();
      return;
    }

    final latitude = prefs.getDouble(AppConstants.keyLatitude);
    final longitude = prefs.getDouble(AppConstants.keyLongitude);

    if (latitude == null || longitude == null) {
      debugPrint('BackgroundService: No location saved, cannot schedule alarms');
      return;
    }

    final coordinates = adhan.Coordinates(latitude, longitude);
    final methodIndex = prefs.getInt(AppConstants.keyCalculationMethod) ?? AppConstants.defaultCalculationMethod;
    final params = _getCalculationParameters(methodIndex);
    final prayerTimes = adhan.PrayerTimes.today(coordinates, params);

    final now = DateTime.now();

    debugPrint('BackgroundService: ========== SCHEDULING ALARMS ==========');
    debugPrint('BackgroundService: Now (local): $now');
    debugPrint('BackgroundService: Now timezone: ${now.timeZoneName} (offset: ${now.timeZoneOffset})');
    debugPrint('BackgroundService: Location: $latitude, $longitude');
    debugPrint('BackgroundService: Method: $methodIndex');
    debugPrint('');
    debugPrint('BackgroundService: Fajr: ${prayerTimes.fajr} (isUtc: ${prayerTimes.fajr.isUtc})');
    debugPrint('BackgroundService: Dhuhr: ${prayerTimes.dhuhr} (isUtc: ${prayerTimes.dhuhr.isUtc})');
    debugPrint('BackgroundService: Asr: ${prayerTimes.asr} (isUtc: ${prayerTimes.asr.isUtc})');
    debugPrint('BackgroundService: Maghrib: ${prayerTimes.maghrib} (isUtc: ${prayerTimes.maghrib.isUtc})');
    debugPrint('BackgroundService: Isha: ${prayerTimes.isha} (isUtc: ${prayerTimes.isha.isUtc})');
    debugPrint('BackgroundService: ======================================');

    // Schedule each prayer alarm if it's in the future
    await _schedulePrayerAlarm(_fajrAlarmId, AppConstants.fajr, prayerTimes.fajr, now);
    await _schedulePrayerAlarm(_dhuhrAlarmId, AppConstants.dhuhr, prayerTimes.dhuhr, now);
    await _schedulePrayerAlarm(_asrAlarmId, AppConstants.asr, prayerTimes.asr, now);
    await _schedulePrayerAlarm(_maghribAlarmId, AppConstants.maghrib, prayerTimes.maghrib, now);
    await _schedulePrayerAlarm(_ishaAlarmId, AppConstants.isha, prayerTimes.isha, now);

    // Schedule daily reschedule at midnight
    await _scheduleDailyReschedule();

    // Save that alarms are active
    await prefs.setBool('alarms_active', true);

    // Print verification of all scheduled alarms
    await printScheduledAlarms();
  }

  Future<void> _schedulePrayerAlarm(int alarmId, String prayerName, DateTime prayerTime, DateTime now) async {
    // FORCE convert to local time - adhan package sometimes returns ambiguous DateTime
    // Create a NEW DateTime with the same hour/minute but guaranteed local timezone
    final localPrayerTime = DateTime(
      prayerTime.year,
      prayerTime.month,
      prayerTime.day,
      prayerTime.hour,
      prayerTime.minute,
      prayerTime.second,
    );

    // Only schedule if prayer time is in the future
    if (localPrayerTime.isAfter(now)) {
      // Save prayer name for this alarm ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_prayer_$alarmId', prayerName);

      // Save scheduled time for verification
      await prefs.setString('alarm_scheduled_$alarmId', localPrayerTime.toIso8601String());

      final minutesUntil = localPrayerTime.difference(now).inMinutes;
      final timeFormat = DateFormat('HH:mm:ss');

      debugPrint('');
      debugPrint('BackgroundService: ┌─────────────────────────────────────');
      debugPrint('BackgroundService: │ SCHEDULING: $prayerName');
      debugPrint('BackgroundService: │ Alarm ID: $alarmId');
      debugPrint('BackgroundService: │ Scheduled Time: ${timeFormat.format(localPrayerTime)}');
      debugPrint('BackgroundService: │ Original prayerTime: $prayerTime (isUtc: ${prayerTime.isUtc})');
      debugPrint('BackgroundService: │ Local prayerTime: $localPrayerTime (isUtc: ${localPrayerTime.isUtc})');
      debugPrint('BackgroundService: │ Current Time: ${timeFormat.format(now)}');
      debugPrint('BackgroundService: │ Minutes Until: $minutesUntil min');
      debugPrint('BackgroundService: └─────────────────────────────────────');

      await AndroidAlarmManager.oneShotAt(
        localPrayerTime,
        alarmId,
        _onPrayerAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );

      debugPrint('BackgroundService: ✓ Alarm $alarmId scheduled successfully');
    } else {
      debugPrint('BackgroundService: ✗ $prayerName already passed (${localPrayerTime.toString()} < ${now.toString()})');
    }
  }

  Future<void> _scheduleDailyReschedule() async {
    // Schedule reschedule at 00:01 next day
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);

    await AndroidAlarmManager.oneShotAt(
      tomorrow,
      _dailyRescheduleAlarmId,
      _onDailyRescheduleCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  /// Cancel all scheduled alarms including test alarm
  Future<void> cancelAllAlarms() async {
    debugPrint('BackgroundService: Cancelling ALL alarms...');
    await AndroidAlarmManager.cancel(999); // Test alarm
    await AndroidAlarmManager.cancel(_fajrAlarmId);
    await AndroidAlarmManager.cancel(_dhuhrAlarmId);
    await AndroidAlarmManager.cancel(_asrAlarmId);
    await AndroidAlarmManager.cancel(_maghribAlarmId);
    await AndroidAlarmManager.cancel(_ishaAlarmId);
    await AndroidAlarmManager.cancel(_dailyRescheduleAlarmId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarms_active', false);
  }

  /// Check if alarms are currently active
  Future<bool> isRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('alarms_active') ?? false;
  }

  /// Print all scheduled alarms for debugging
  Future<void> printScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    debugPrint('');
    debugPrint('╔═══════════════════════════════════════════════════════════════╗');
    debugPrint('║           SCHEDULED ALARMS VERIFICATION                       ║');
    debugPrint('╠═══════════════════════════════════════════════════════════════╣');
    debugPrint('║ Current Time: ${dateFormat.format(now)}');
    debugPrint('║ Timezone: ${now.timeZoneName} (offset: ${now.timeZoneOffset})');
    debugPrint('║ Alarms Active: ${prefs.getBool('alarms_active') ?? false}');
    debugPrint('╠═══════════════════════════════════════════════════════════════╣');

    final alarmIds = {
      _fajrAlarmId: AppConstants.fajr,
      _dhuhrAlarmId: AppConstants.dhuhr,
      _asrAlarmId: AppConstants.asr,
      _maghribAlarmId: AppConstants.maghrib,
      _ishaAlarmId: AppConstants.isha,
      999: 'Test Alarm',
    };

    for (final entry in alarmIds.entries) {
      final alarmId = entry.key;
      final defaultName = entry.value;
      final prayerName = prefs.getString('alarm_prayer_$alarmId') ?? defaultName;
      final scheduledTimeStr = prefs.getString('alarm_scheduled_$alarmId');

      if (scheduledTimeStr != null) {
        final scheduledTime = DateTime.parse(scheduledTimeStr);
        final isPast = scheduledTime.isBefore(now);
        final diff = scheduledTime.difference(now);
        final status = isPast ? '⏰ PASSED' : '✓ PENDING';
        final timeUntil = isPast
            ? '${diff.inMinutes.abs()} min ago'
            : 'in ${diff.inMinutes} min';

        debugPrint('║ [$alarmId] $prayerName');
        debugPrint('║     Time: ${timeFormat.format(scheduledTime)} | $status | $timeUntil');
      } else {
        debugPrint('║ [$alarmId] $prayerName: NOT SCHEDULED');
      }
    }

    debugPrint('╚═══════════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Start service (schedule all alarms)
  Future<void> startService() async {
    await scheduleAllPrayerAlarms();
  }

  /// Stop service (cancel all alarms)
  Future<void> stopService() async {
    await cancelAllAlarms();
  }

  /// TEST: Schedule a test alarm at specific time for debugging
  /// Usage: await backgroundService.scheduleTestAlarm(hour: 5, minute: 15);
  Future<void> scheduleTestAlarm({
    required int hour,
    required int minute,
    String prayerName = 'Test Subuh',
  }) async {
    const testAlarmId = 999;

    final now = DateTime.now();
    var testTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has passed today, schedule for tomorrow
    if (testTime.isBefore(now)) {
      testTime = testTime.add(const Duration(days: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_prayer_$testAlarmId', prayerName);
    await prefs.setString('alarm_scheduled_$testAlarmId', testTime.toIso8601String());
    await prefs.setBool(AppConstants.keyAdhanEnabled, true);

    // Clear any previous test played flag
    final today = testTime.day;
    await prefs.remove('last_played_${prayerName}_$today');

    debugPrint('=== TEST ALARM SCHEDULED ===');
    debugPrint('Prayer: $prayerName');
    debugPrint('Time: $testTime');
    debugPrint('Now: $now');
    debugPrint('Minutes until alarm: ${testTime.difference(now).inMinutes}');
    debugPrint('============================');

    await AndroidAlarmManager.oneShotAt(
      testTime,
      testAlarmId,
      _onPrayerAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  /// Cancel test alarm
  Future<void> cancelTestAlarm() async {
    await AndroidAlarmManager.cancel(999);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_scheduled_999');
    debugPrint('Test alarm cancelled');
  }

  /// TEST: Schedule alarm X minutes from now (easier for testing)
  Future<void> scheduleTestAlarmInMinutes(int minutes) async {
    final now = DateTime.now();
    final testTime = now.add(Duration(minutes: minutes));
    await scheduleTestAlarm(
      hour: testTime.hour,
      minute: testTime.minute,
      prayerName: 'Test ${minutes}min',
    );

    // Print verification
    await printScheduledAlarms();
  }

  /// IMPORTANT: This must match PrayerRepository._getCalculationParameters()
  adhan.CalculationParameters _getCalculationParameters(int methodIndex) {
    switch (methodIndex) {
      case 1:
        return adhan.CalculationMethod.karachi.getParameters();
      case 2:
        return adhan.CalculationMethod.north_america.getParameters();
      case 3:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case 4:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 5:
        return adhan.CalculationMethod.egyptian.getParameters();
      case 11:
        return adhan.CalculationMethod.singapore.getParameters();
      case 13:
        return adhan.CalculationMethod.turkey.getParameters();
      case 15:
        return adhan.CalculationMethod.moon_sighting_committee.getParameters();
      default:
        return adhan.CalculationMethod.singapore.getParameters();
    }
  }
}

/// Callback when prayer alarm fires - runs in isolate
@pragma('vm:entry-point')
Future<void> _onPrayerAlarmCallback(int alarmId) async {
  final now = DateTime.now();

  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════════════════════════╗');
  debugPrint('║              🔔 ALARM CALLBACK TRIGGERED 🔔                   ║');
  debugPrint('╠═══════════════════════════════════════════════════════════════╣');
  debugPrint('║ Alarm ID: $alarmId');
  debugPrint('║ Triggered At: $now');
  debugPrint('║ Timezone: ${now.timeZoneName} (offset: ${now.timeZoneOffset})');
  debugPrint('╚═══════════════════════════════════════════════════════════════╝');

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Reload prefs to get fresh data
  await prefs.reload();

  // Log scheduled vs actual time
  final scheduledTimeStr = prefs.getString('alarm_scheduled_$alarmId');
  if (scheduledTimeStr != null) {
    final scheduledTime = DateTime.parse(scheduledTimeStr);
    final diff = now.difference(scheduledTime);
    debugPrint('BackgroundService: Scheduled: $scheduledTime | Actual: $now | Diff: ${diff.inSeconds}s');
  }

  // Check if adhan is still enabled
  final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;
  if (!adhanEnabled) {
    debugPrint('BackgroundService: Adhan disabled, skipping');
    return;
  }

  // Get prayer name from saved preference
  final prayerName = prefs.getString('alarm_prayer_$alarmId') ?? 'Sholat';
  debugPrint('BackgroundService: Playing adhan for $prayerName');

  // Check if already played today (BEFORE playing to prevent race condition)
  final today = DateTime.now().day;
  final lastPlayedKey = 'last_played_${prayerName}_$today';
  final lastPlayed = prefs.getBool(lastPlayedKey) ?? false;

  if (lastPlayed) {
    debugPrint('BackgroundService: Already played $prayerName today, skipping');
    return;
  }

  // Check if adhan is currently playing (cross-isolate check via SharedPreferences)
  final isCurrentlyPlaying = prefs.getBool('adhan_is_playing') ?? false;
  if (isCurrentlyPlaying) {
    debugPrint('BackgroundService: Adhan already playing, skipping');
    return;
  }

  // IMMEDIATELY mark as played and playing to prevent duplicate triggers
  await prefs.setBool(lastPlayedKey, true);
  await prefs.setBool('adhan_is_playing', true);

  // Set file-based flag for cross-isolate communication
  await StopFlagService.setPlaying(true);
  await StopFlagService.setStopRequested(false);

  // Small delay to ensure data is persisted before main isolate checks
  await Future.delayed(const Duration(milliseconds: 100));

  // Verify flags are set
  final verifyPrefs = prefs.getBool('adhan_is_playing');
  final verifyFile = await StopFlagService.isPlaying();
  debugPrint('BackgroundService: *** FLAGS SET - prefs=$verifyPrefs, file=$verifyFile ***');

  try {
    // Initialize and show notification first
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.showAdhanNotification(
      id: alarmId,
      prayerName: prayerName,
    );
    debugPrint('BackgroundService: Notification shown');

    // Initialize AudioService with proper foreground notification
    // This keeps the audio playing even when system tries to kill it
    debugPrint('BackgroundService: Initializing AudioService...');

    late AdhanAudioHandler audioHandler;
    try {
      audioHandler = await AudioService.init(
        builder: () => AdhanAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.kesholat.app.adhan.background',
          androidNotificationChannelName: 'Adhan Background Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'mipmap/ic_launcher',
          preloadArtwork: false,
          artDownloadEnabled: false,
        ),
      );
      debugPrint('BackgroundService: AudioService initialized successfully');
    } catch (e) {
      debugPrint('BackgroundService: AudioService init error: $e');
      // Fallback: try direct audio player if AudioService fails
      await _playWithFallbackPlayer(prefs, prayerName);
      return;
    }

    try {
      final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
      await audioHandler.setVolume(volume);
      debugPrint('BackgroundService: Volume set to $volume');

      // Set media item for notification
      audioHandler.mediaItem.add(MediaItem(
        id: 'adhan_$prayerName',
        title: 'Adzan $prayerName',
        artist: 'KeSholat',
        duration: const Duration(minutes: 5),
      ));

      // Load and play the adhan audio
      final assetPath = 'assets/audio/${AppConstants.adhanFile}';
      debugPrint('BackgroundService: Playing audio from $assetPath');

      await audioHandler.playFromAsset(assetPath);
      debugPrint('BackgroundService: Playback started with AudioService');

      // Poll for completion or stop request
      int loopCount = 0;
      final startTime = DateTime.now();
      const maxDuration = Duration(minutes: 10); // Safety timeout

      debugPrint('BackgroundService: ===== POLLING LOOP STARTED (AudioService) =====');

      while (true) {
        await Future.delayed(const Duration(milliseconds: 500));
        loopCount++;

        final elapsed = DateTime.now().difference(startTime);
        final playbackState = audioHandler.playbackState.value;
        final processingState = playbackState.processingState;
        final isPlaying = playbackState.playing;

        // Check stop request
        final fileStopRequested = StopFlagService.isStopRequestedSync();
        await prefs.reload();
        final prefsStopRequested = prefs.getBool('adhan_stop_requested') ?? false;
        final stopRequested = fileStopRequested || prefsStopRequested;

        // Log every 5 seconds
        if (loopCount % 10 == 0) {
          debugPrint('BackgroundService: [Loop $loopCount] playing=$isPlaying, state=$processingState, elapsed=${elapsed.inSeconds}s');
        }

        // Stop requested by user
        if (stopRequested) {
          debugPrint('BackgroundService: Stop requested, stopping AudioService');
          await audioHandler.stop();
          await StopFlagService.setStopRequested(false);
          await prefs.setBool('adhan_stop_requested', false);
          break;
        }

        // Playback completed
        if (processingState == AudioProcessingState.completed) {
          debugPrint('BackgroundService: Playback completed normally after ${elapsed.inSeconds}s');
          break;
        }

        // AudioService idle = completed or error
        if (processingState == AudioProcessingState.idle && loopCount > 10) {
          debugPrint('BackgroundService: AudioService idle after ${elapsed.inSeconds}s');
          break;
        }

        // Safety timeout
        if (elapsed > maxDuration) {
          debugPrint('BackgroundService: Safety timeout reached');
          await audioHandler.stop();
          break;
        }
      }

      debugPrint('BackgroundService: ===== POLLING LOOP ENDED =====');
    } finally {
      // Stop and cleanup AudioService
      try {
        await audioHandler.stop();
      } catch (e) {
        debugPrint('BackgroundService: Error stopping audioHandler: $e');
      }

      // Clear all flags
      await StopFlagService.clearAllFlags();
      await prefs.setBool('adhan_stop_requested', false);

      // Cancel our custom notification
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.cancel(AppConstants.adhanNotificationId);
      debugPrint('BackgroundService: AudioService stopped, notifications cancelled');
    }
  } catch (e, stack) {
    debugPrint('BackgroundService: Error playing adhan: $e');
    debugPrint('BackgroundService: Stack trace: $stack');
  } finally {
    // Always clear playing flag when done
    await prefs.setBool('adhan_is_playing', false);
    await StopFlagService.setPlaying(false);
    debugPrint('BackgroundService: Playing flag cleared');
  }
}

/// Fallback player when AudioService fails to initialize
Future<void> _playWithFallbackPlayer(SharedPreferences prefs, String prayerName) async {
  debugPrint('BackgroundService: Using fallback AudioPlayer');

  final audioPlayer = AudioPlayer();
  try {
    final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
    await audioPlayer.setVolume(volume);

    final assetPath = 'assets/audio/${AppConstants.adhanFile}';
    await audioPlayer.setAsset(assetPath);
    await audioPlayer.play();

    // Wait for completion with simple polling
    int loopCount = 0;
    while (audioPlayer.playing || audioPlayer.processingState == ProcessingState.buffering) {
      await Future.delayed(const Duration(milliseconds: 500));
      loopCount++;

      // Check stop request
      final stopRequested = StopFlagService.isStopRequestedSync();
      if (stopRequested) {
        debugPrint('BackgroundService: Fallback - stop requested');
        break;
      }

      // Check completion
      if (audioPlayer.processingState == ProcessingState.completed) {
        debugPrint('BackgroundService: Fallback - completed');
        break;
      }

      // Safety timeout 10 min
      if (loopCount > 1200) {
        debugPrint('BackgroundService: Fallback - timeout');
        break;
      }
    }
  } finally {
    await audioPlayer.stop();
    await audioPlayer.dispose();
    await StopFlagService.clearAllFlags();
    await prefs.setBool('adhan_is_playing', false);
    debugPrint('BackgroundService: Fallback player disposed');
  }
}

/// Callback for daily reschedule at midnight
@pragma('vm:entry-point')
Future<void> _onDailyRescheduleCallback(int alarmId) async {
  final now = DateTime.now();

  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════════════════════════╗');
  debugPrint('║          🌙 DAILY RESCHEDULE CALLBACK (00:01) 🌙              ║');
  debugPrint('╠═══════════════════════════════════════════════════════════════╣');
  debugPrint('║ Triggered At: $now');
  debugPrint('║ This will reschedule all prayer alarms for today');
  debugPrint('╚═══════════════════════════════════════════════════════════════╝');

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Clear yesterday's played flags
  final prefs = await SharedPreferences.getInstance();
  final yesterday = DateTime.now().subtract(const Duration(days: 1)).day;
  final today = DateTime.now().day;

  debugPrint('BackgroundService: Clearing flags for yesterday (day=$yesterday)');
  for (final prayer in [AppConstants.fajr, AppConstants.dhuhr, AppConstants.asr, AppConstants.maghrib, AppConstants.isha]) {
    await prefs.remove('last_played_${prayer}_$yesterday');
    // Also clear today's flags in case they were set incorrectly
    await prefs.remove('last_played_${prayer}_$today');
  }

  // Clear old scheduled times
  for (int i = 1; i <= 5; i++) {
    await prefs.remove('alarm_scheduled_$i');
  }

  // Reschedule all prayer alarms for today
  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  await backgroundService.scheduleAllPrayerAlarms();

  debugPrint('BackgroundService: ✓ Daily reschedule complete - alarms set for today');
}