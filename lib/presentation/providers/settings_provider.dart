import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../services/audio_service.dart';
import '../../services/background_service.dart';

class SettingsProvider extends ChangeNotifier {
  final AdhanAudioService _audioService;
  final BackgroundService _backgroundService;

  bool _adhanEnabled = true;
  bool _notificationEnabled = true;
  double _adhanVolume = 1.0;
  int _calculationMethod = AppConstants.defaultCalculationMethod;
  bool _isBackgroundServiceRunning = false;
  String? _audioError;
  bool _isAdhanAvailable = false;

  SettingsProvider({
    AdhanAudioService? audioService,
    BackgroundService? backgroundService,
  })  : _audioService = audioService ?? AdhanAudioService(),
        _backgroundService = backgroundService ?? BackgroundService();

  bool get adhanEnabled => _adhanEnabled;
  bool get notificationEnabled => _notificationEnabled;
  double get adhanVolume => _adhanVolume;
  int get calculationMethod => _calculationMethod;
  bool get isBackgroundServiceRunning => _isBackgroundServiceRunning;
  String? get audioError => _audioError;
  bool get isPlaying => _audioService.isPlaying;
  bool get isAdhanAvailable => _isAdhanAvailable;

  Future<void> initialize() async {
    // Initialize audio service first
    await _audioService.initialize();

    final prefs = await SharedPreferences.getInstance();

    _adhanEnabled = prefs.getBool(AppConstants.keyAdhanEnabled) ?? true;
    _notificationEnabled = prefs.getBool(AppConstants.keyNotificationEnabled) ?? true;
    _adhanVolume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
    _calculationMethod = prefs.getInt(AppConstants.keyCalculationMethod) ?? AppConstants.defaultCalculationMethod;

    _isBackgroundServiceRunning = await _backgroundService.isRunning();
    _isAdhanAvailable = await _audioService.isAdhanFileAvailable();

    notifyListeners();
  }

  Future<void> setAdhanEnabled(bool enabled) async {
    _adhanEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAdhanEnabled, enabled);

    // Reschedule alarms based on new setting
    if (_isBackgroundServiceRunning) {
      if (enabled) {
        await _backgroundService.scheduleAllPrayerAlarms();
      } else {
        await _backgroundService.cancelAllAlarms();
        _isBackgroundServiceRunning = false;
      }
    }

    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    _notificationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationEnabled, enabled);
    notifyListeners();
  }

  Future<void> setAdhanVolume(double volume) async {
    _adhanVolume = volume.clamp(0.0, 1.0);
    await _audioService.setVolume(_adhanVolume);
    notifyListeners();
  }

  Future<void> setCalculationMethod(int method) async {
    _calculationMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCalculationMethod, method);

    // Reschedule alarms with new calculation method
    if (_isBackgroundServiceRunning) {
      await _backgroundService.scheduleAllPrayerAlarms();
    }

    notifyListeners();
  }

  Future<bool> playAdhanPreview() async {
    _audioError = null;
    final success = await _audioService.playAdhan();
    if (!success) {
      _audioError = _audioService.lastError;
    }
    notifyListeners();
    return success;
  }

  Future<void> stopAdhanPreview() async {
    await _audioService.stopAdhan();
    notifyListeners();
  }

  void clearAudioError() {
    _audioError = null;
    notifyListeners();
  }

  Future<void> startBackgroundService() async {
    await _backgroundService.startService();
    _isBackgroundServiceRunning = await _backgroundService.isRunning();
    notifyListeners();
  }

  Future<void> stopBackgroundService() async {
    await _backgroundService.stopService();
    _isBackgroundServiceRunning = false;
    notifyListeners();
  }

  Future<void> toggleBackgroundService() async {
    if (_isBackgroundServiceRunning) {
      await stopBackgroundService();
    } else {
      await startBackgroundService();
    }
  }
}
