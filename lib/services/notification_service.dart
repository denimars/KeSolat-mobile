import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/prayer_time.dart';
import 'stop_flag_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _createNotificationChannels();
    _isInitialized = true;
    debugPrint('NotificationService: Initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.prayerNotificationChannelId,
          AppConstants.prayerNotificationChannelName,
          description: AppConstants.prayerNotificationChannelDesc,
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.adhanNotificationChannelId,
          AppConstants.adhanNotificationChannelName,
          description: AppConstants.adhanNotificationChannelDesc,
          importance: Importance.max,
          playSound: false,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.backgroundServiceChannelId,
          AppConstants.backgroundServiceChannelName,
          description: AppConstants.backgroundServiceChannelDesc,
          importance: Importance.low,
          playSound: false,
        ),
      );
    }
  }

  /// Stop adhan and cancel notification - called from app
  Future<void> stopAdhanAndCancelNotification() async {
    debugPrint('NotificationService: Stopping adhan...');

    // Use FILE-BASED flag for reliable cross-isolate communication
    await StopFlagService.setStopRequested(true);
    await StopFlagService.setPlaying(false);
    debugPrint('NotificationService: File-based stop flag SET');

    // Also set SharedPreferences as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_stop_requested', true);
    await prefs.setBool('adhan_is_playing', false);

    // Cancel the notification
    await _notifications.cancel(AppConstants.adhanNotificationId);

    debugPrint('NotificationService: Adhan stop requested, notification cancelled');
  }

  Future<bool> requestPermission() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  Future<void> showPrayerNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.prayerNotificationChannelId,
      AppConstants.prayerNotificationChannelName,
      channelDescription: AppConstants.prayerNotificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> showAdhanNotification({
    required int id,
    required String prayerName,
  }) async {
    // Clear any previous stop request
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_stop_requested', false);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.adhanNotificationChannelId,
      AppConstants.adhanNotificationChannelName,
      channelDescription: AppConstants.adhanNotificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: false,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      playSound: false,
      // No action buttons - stop is handled in app
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.adhanNotificationId,
      'Waktu $prayerName',
      'Adzan sedang berkumandang. Buka app untuk menghentikan.',
      details,
      payload: 'adhan_$prayerName',
    );

    debugPrint('NotificationService: Adhan notification shown for $prayerName');
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required PrayerTime prayer,
    required Duration beforePrayer,
  }) async {
    final scheduledTime = prayer.time.subtract(beforePrayer);
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.prayerNotificationChannelId,
      AppConstants.prayerNotificationChannelName,
      channelDescription: AppConstants.prayerNotificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Waktu ${prayer.name} Sebentar Lagi',
      '${beforePrayer.inMinutes} menit menuju waktu ${prayer.name}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
