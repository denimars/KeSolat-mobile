import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../core/constants/app_constants.dart';
import 'notification_service.dart';
import 'audio_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: AppConstants.backgroundServiceChannelId,
        initialNotificationTitle: AppConstants.backgroundServiceNotificationTitle,
        initialNotificationContent: AppConstants.backgroundServiceNotificationContent,
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
  }

  Future<void> stopService() async {
    _service.invoke('stop');
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final audioService = AdhanAudioService();
  await audioService.initialize();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(
    const Duration(seconds: AppConstants.prayerCheckIntervalSeconds),
    (timer) async {
      await _checkPrayerTime(notificationService, audioService);

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: AppConstants.backgroundServiceNotificationTitle,
            content: 'Last check: ${DateTime.now().toString().substring(11, 19)}',
          );
        }
      }

      service.invoke('update', {
        'current_time': DateTime.now().toIso8601String(),
      });
    },
  );
}

Future<void> _checkPrayerTime(
  NotificationService notificationService,
  AdhanAudioService audioService,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;
    if (!adhanEnabled) return;

    final latitude = prefs.getDouble(AppConstants.keyLatitude);
    final longitude = prefs.getDouble(AppConstants.keyLongitude);

    if (latitude == null || longitude == null) return;

    final coordinates = adhan.Coordinates(latitude, longitude);
    final params = adhan.CalculationMethod.singapore.getParameters();
    final prayerTimes = adhan.PrayerTimes.today(coordinates, params);

    final now = DateTime.now();
    final prayers = {
      AppConstants.fajr: prayerTimes.fajr,
      AppConstants.dhuhr: prayerTimes.dhuhr,
      AppConstants.asr: prayerTimes.asr,
      AppConstants.maghrib: prayerTimes.maghrib,
      AppConstants.isha: prayerTimes.isha,
    };

    for (final entry in prayers.entries) {
      final prayerTime = entry.value;
      final diff = now.difference(prayerTime).inSeconds.abs();

      if (diff <= 30) {
        final lastPlayedKey = 'last_played_${entry.key}_${now.day}';
        final lastPlayed = prefs.getBool(lastPlayedKey) ?? false;

        if (!lastPlayed) {
          await notificationService.showAdhanNotification(
            id: entry.key.hashCode,
            prayerName: entry.key,
          );

          await audioService.playAdhan();
          await prefs.setBool(lastPlayedKey, true);
        }
        break;
      }
    }
  } catch (e) {
    // Handle error silently in background
  }
}
