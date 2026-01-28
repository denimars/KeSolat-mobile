import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import 'notification_service.dart';
import 'stop_flag_service.dart';

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

    debugPrint('BackgroundService: Scheduling alarms for today');
    debugPrint('BackgroundService: Fajr: ${prayerTimes.fajr}');
    debugPrint('BackgroundService: Dhuhr: ${prayerTimes.dhuhr}');
    debugPrint('BackgroundService: Asr: ${prayerTimes.asr}');
    debugPrint('BackgroundService: Maghrib: ${prayerTimes.maghrib}');
    debugPrint('BackgroundService: Isha: ${prayerTimes.isha}');

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
  }

  Future<void> _schedulePrayerAlarm(int alarmId, String prayerName, DateTime prayerTime, DateTime now) async {
    // Only schedule if prayer time is in the future
    if (prayerTime.isAfter(now)) {
      // Save prayer name for this alarm ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_prayer_$alarmId', prayerName);

      debugPrint('BackgroundService: Scheduling $prayerName alarm at $prayerTime');

      await AndroidAlarmManager.oneShotAt(
        prayerTime,
        alarmId,
        _onPrayerAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
    } else {
      debugPrint('BackgroundService: $prayerName already passed, not scheduling');
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

  /// Cancel all scheduled alarms
  Future<void> cancelAllAlarms() async {
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
    debugPrint('Test alarm cancelled');
  }

  adhan.CalculationParameters _getCalculationParameters(int methodIndex) {
    switch (methodIndex) {
      case 0:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case 1:
        return adhan.CalculationMethod.egyptian.getParameters();
      case 2:
        return adhan.CalculationMethod.karachi.getParameters();
      case 3:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 4:
        return adhan.CalculationMethod.dubai.getParameters();
      case 5:
        return adhan.CalculationMethod.qatar.getParameters();
      case 6:
        return adhan.CalculationMethod.kuwait.getParameters();
      case 7:
        return adhan.CalculationMethod.moon_sighting_committee.getParameters();
      case 8:
        return adhan.CalculationMethod.singapore.getParameters();
      case 9:
        return adhan.CalculationMethod.north_america.getParameters();
      case 10:
        return adhan.CalculationMethod.turkey.getParameters();
      case 11:
        return adhan.CalculationMethod.tehran.getParameters();
      default:
        return adhan.CalculationMethod.singapore.getParameters();
    }
  }
}

/// Callback when prayer alarm fires - runs in isolate
@pragma('vm:entry-point')
Future<void> _onPrayerAlarmCallback(int alarmId) async {
  debugPrint('BackgroundService: Alarm callback triggered for alarm ID: $alarmId');

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Reload prefs to get fresh data
  await prefs.reload();

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
  await StopFlagService.setPlaying(true);
  await StopFlagService.setStopRequested(false);
  debugPrint('BackgroundService: *** adhan_is_playing set to TRUE ***');

  try {
    // Initialize and show notification first
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.showAdhanNotification(
      id: alarmId,
      prayerName: prayerName,
    );
    debugPrint('BackgroundService: Notification shown');

    // Create audio player directly in this isolate
    final audioPlayer = AudioPlayer();

    try {
      final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
      await audioPlayer.setVolume(volume);
      debugPrint('BackgroundService: Volume set to $volume');

      // Load and play the adhan audio
      final assetPath = 'assets/audio/${AppConstants.adhanFile}';
      debugPrint('BackgroundService: Loading audio from $assetPath');

      await audioPlayer.setAsset(assetPath);
      debugPrint('BackgroundService: Audio loaded, starting playback');

      // Start playback (don't await - it blocks until complete)
      // ignore: unawaited_futures
      audioPlayer.play();

      // Wait a moment for playback to initialize
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('BackgroundService: Playback initiated, playing=${audioPlayer.playing}, state=${audioPlayer.processingState}');

      // Poll for completion or stop request
      int loopCount = 0;

      // Log the flag path we're checking
      final flagPath = await StopFlagService.getStopFlagFilePath();
      debugPrint('BackgroundService: ===== POLLING LOOP STARTED =====');
      debugPrint('BackgroundService: Checking stop flag at: $flagPath');

      // Continue while audio is playing or buffering
      while (audioPlayer.playing || audioPlayer.processingState == ProcessingState.buffering || audioPlayer.processingState == ProcessingState.loading) {
        await Future.delayed(const Duration(milliseconds: 300));
        loopCount++;

        // Check BOTH file-based flag AND SharedPreferences for maximum reliability
        final fileStopRequested = StopFlagService.isStopRequestedSync();

        // Also check SharedPreferences as fallback
        await prefs.reload();
        final prefsStopRequested = prefs.getBool('adhan_stop_requested') ?? false;

        final stopRequested = fileStopRequested || prefsStopRequested;

        // Log every loop for debugging
        if (loopCount % 10 == 0) { // Log every 3 seconds
          debugPrint('BackgroundService: [Loop $loopCount] fileStop=$fileStopRequested, prefsStop=$prefsStopRequested');
        }

        if (stopRequested) {
          debugPrint('BackgroundService: !!!!! STOP DETECTED - STOPPING AUDIO NOW !!!!!');
          await audioPlayer.stop();
          await StopFlagService.setStopRequested(false);
          await prefs.setBool('adhan_stop_requested', false);
          debugPrint('BackgroundService: Audio stopped successfully');
          break;
        }

        // Check if playback completed
        if (audioPlayer.processingState == ProcessingState.completed) {
          debugPrint('BackgroundService: Playback completed normally');
          break;
        }

        // Safety timeout after 10 minutes
        if (loopCount > 2000) {
          debugPrint('BackgroundService: Safety timeout reached');
          break;
        }
      }

      debugPrint('BackgroundService: ===== POLLING LOOP ENDED =====');
    } finally {
      await audioPlayer.stop();
      await audioPlayer.dispose();
      // Clear all flags
      await StopFlagService.clearAllFlags();
      await prefs.setBool('adhan_stop_requested', false);
      // Cancel notification
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.cancel(AppConstants.adhanNotificationId);
      debugPrint('BackgroundService: Audio player disposed, notification cancelled');
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

/// Callback for daily reschedule at midnight
@pragma('vm:entry-point')
Future<void> _onDailyRescheduleCallback(int alarmId) async {
  debugPrint('BackgroundService: Daily reschedule callback triggered');

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Clear yesterday's played flags
  final prefs = await SharedPreferences.getInstance();
  final yesterday = DateTime.now().subtract(const Duration(days: 1)).day;
  for (final prayer in [AppConstants.fajr, AppConstants.dhuhr, AppConstants.asr, AppConstants.maghrib, AppConstants.isha]) {
    await prefs.remove('last_played_${prayer}_$yesterday');
  }

  // Reschedule all prayer alarms for today
  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  await backgroundService.scheduleAllPrayerAlarms();

  debugPrint('BackgroundService: Alarms rescheduled for today');
}