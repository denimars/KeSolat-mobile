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

  // Essential initialization only - keep minimal for fast startup
  await initializeDateFormatting('id_ID', null);

  // Set UI preferences immediately
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Run app first, then initialize services in background
  runApp(const KeSholatApp());

  // Initialize services after UI is shown (non-blocking)
  _initializeServicesInBackground();
}

/// Initialize services after app is displayed to avoid blocking UI
Future<void> _initializeServicesInBackground() async {
  try {
    // Small delay to let UI render first
    await Future.delayed(const Duration(milliseconds: 100));

    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermission();

    final audioService = AdhanAudioService();
    await audioService.initialize();

    // Clear stop request flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_stop_requested', false);
    await StopFlagService.setStopRequested(false);

    // Initialize AlarmManager
    final backgroundService = BackgroundService();
    await backgroundService.initialize();

    // Schedule alarms if location exists and adhan is enabled
    final lat = prefs.getDouble(AppConstants.keyLatitude);
    final lng = prefs.getDouble(AppConstants.keyLongitude);
    final hasLocation = lat != null && lng != null;
    final adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;

    debugPrint('main: hasLocation=$hasLocation, adhanEnabled=$adhanEnabled');

    if (hasLocation && adhanEnabled) {
      debugPrint('main: Scheduling prayer alarms...');
      await backgroundService.scheduleAllPrayerAlarms();
    }

    // ============ TEST ALARM ============
    // Test alarm 3 menit dari sekarang
    await backgroundService.scheduleTestAlarmInMinutes(3);
    // ====================================

    debugPrint('main: Background initialization complete');
  } catch (e) {
    debugPrint('main: Error in background init: $e');
  }
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
