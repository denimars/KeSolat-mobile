import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/audio_service.dart';
import 'services/stop_flag_service.dart';
import 'presentation/providers/prayer_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/qibla_provider.dart';
import 'presentation/views/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  final audioService = AdhanAudioService();
  await audioService.initialize();

  // Clear only stop request flag (not playing flag - adzan might be playing in background)
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('adhan_stop_requested', false);
  await StopFlagService.setStopRequested(false);
  // Note: Don't clear 'adhan_is_playing' or playing flag - background service manages these

  // Initialize AlarmManager for prayer time alarms
  final backgroundService = BackgroundService();
  await backgroundService.initialize();

  // Schedule alarms if location exists and adhan is enabled
  final hasLocation = prefs.getDouble(AppConstants.keyLatitude) != null &&
      prefs.getDouble(AppConstants.keyLongitude) != null;
  final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;

  if (hasLocation && adhanEnabled) {
    debugPrint('main: Location exists and adhan enabled, scheduling alarms...');
    await backgroundService.scheduleAllPrayerAlarms();
  }

  // ============ TEST ALARM ============
  // Uncomment untuk test alarm. Ganti hour & minute sesuai kebutuhan.
  await backgroundService.scheduleTestAlarm(
    hour: 14,
    minute: 13,
    prayerName: 'Test Adzan',
  );
  // ====================================

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const KeSholatApp());
}

class KeSholatApp extends StatelessWidget {
  const KeSholatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => QiblaProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
