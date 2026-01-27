import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../core/constants/app_constants.dart';
import 'notification_service.dart';
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

    if (latitude == null || longitude == null) return;

    final coordinates = adhan.Coordinates(latitude, longitude);
    final methodIndex = prefs.getInt(AppConstants.keyCalculationMethod) ?? AppConstants.defaultCalculationMethod;
    final params = _getCalculationParameters(methodIndex);
    final prayerTimes = adhan.PrayerTimes.today(coordinates, params);

    final now = DateTime.now();

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

      await AndroidAlarmManager.oneShotAt(
        prayerTime,
        alarmId,
        _onPrayerAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
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
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Check if adhan is still enabled
  final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;
  if (!adhanEnabled) return;

  // Get prayer name from saved preference
  final prayerName = prefs.getString('alarm_prayer_$alarmId') ?? 'Sholat';

  // Check if already played today (BEFORE playing to prevent race condition)
  final today = DateTime.now().day;
  final lastPlayedKey = 'last_played_${prayerName}_$today';
  final lastPlayed = prefs.getBool(lastPlayedKey) ?? false;

  if (lastPlayed) return;

  // Check if adhan is currently playing (cross-isolate check via SharedPreferences)
  final isCurrentlyPlaying = prefs.getBool('adhan_is_playing') ?? false;
  if (isCurrentlyPlaying) return;

  // IMMEDIATELY mark as played and playing to prevent duplicate triggers
  await prefs.setBool(lastPlayedKey, true);
  await prefs.setBool('adhan_is_playing', true);

  try {
    // Initialize and show notification
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.showAdhanNotification(
      id: alarmId,
      prayerName: prayerName,
    );

    // Initialize and play audio
    final audioService = AdhanAudioService();
    await audioService.initialize();

    final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
    await audioService.setVolume(volume);
    await audioService.playAdhan();

    // Wait for audio to complete (typical adhan is ~3-5 minutes)
    // Listen to completion or wait max duration
    await Future.delayed(const Duration(minutes: 5));
  } finally {
    // Always clear playing flag when done
    await prefs.setBool('adhan_is_playing', false);
  }
}

/// Callback for daily reschedule at midnight
@pragma('vm:entry-point')
Future<void> _onDailyRescheduleCallback(int alarmId) async {
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
}
