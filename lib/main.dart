import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/audio_service.dart';
import 'presentation/providers/prayer_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/qibla_provider.dart';
import 'presentation/views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  final audioService = AdhanAudioService();
  await audioService.initialize();

  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  await backgroundService.startService();

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
        home: const HomeScreen(),
      ),
    );
  }
}
