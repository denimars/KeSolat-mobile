import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/daily_prayer_schedule.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/prayer_time.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerRepository _prayerRepository;
  final LocationService _locationService;

  DailyPrayerSchedule? _todaySchedule;
  Location? _currentLocation;
  PrayerTime? _nextPrayer;
  Duration? _timeUntilNextPrayer;
  bool _isLoading = false;
  String? _error;
  int _calculationMethod = AppConstants.defaultCalculationMethod;
  Timer? _countdownTimer;

  PrayerProvider({
    PrayerRepository? prayerRepository,
    LocationService? locationService,
  })  : _prayerRepository = prayerRepository ?? PrayerRepository(),
        _locationService = locationService ?? LocationService();

  DailyPrayerSchedule? get todaySchedule => _todaySchedule;
  Location? get currentLocation => _currentLocation;
  PrayerTime? get nextPrayer => _nextPrayer;
  Duration? get timeUntilNextPrayer => _timeUntilNextPrayer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get calculationMethod => _calculationMethod;

  Future<void> initialize() async {
    await _loadSavedLocation();
    await _loadCalculationMethod();

    if (_currentLocation != null) {
      await loadTodayPrayerTimes();
    }

    _startCountdownTimer();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(AppConstants.keyLatitude);
    final longitude = prefs.getDouble(AppConstants.keyLongitude);
    final city = prefs.getString(AppConstants.keyCity);
    final country = prefs.getString(AppConstants.keyCountry);

    if (latitude != null && longitude != null) {
      _currentLocation = Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );
    }
  }

  Future<void> _loadCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    _calculationMethod = prefs.getInt(AppConstants.keyCalculationMethod) ??
        AppConstants.defaultCalculationMethod;
  }

  Future<void> _saveLocation(Location location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLatitude, location.latitude);
    await prefs.setDouble(AppConstants.keyLongitude, location.longitude);
    if (location.city != null) {
      await prefs.setString(AppConstants.keyCity, location.city!);
    }
    if (location.country != null) {
      await prefs.setString(AppConstants.keyCountry, location.country!);
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        await _saveLocation(location);
        await loadTodayPrayerTimes();
      } else {
        _error = 'Gagal mendapatkan lokasi. Pastikan GPS aktif dan izin lokasi diberikan.';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan saat mendapatkan lokasi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setManualLocation(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = await _locationService.getLocationFromCoordinates(latitude, longitude);
      if (location != null) {
        _currentLocation = location;
        await _saveLocation(location);
        await loadTodayPrayerTimes();
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTodayPrayerTimes() async {
    if (_currentLocation == null) {
      _error = 'Lokasi belum diatur';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todaySchedule = _prayerRepository.calculatePrayerTimes(
        location: _currentLocation!,
        date: DateTime.now(),
        method: _calculationMethod,
      );

      _updateNextPrayer();
    } catch (e) {
      _error = 'Gagal menghitung waktu sholat: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateNextPrayer() {
    if (_todaySchedule == null) return;

    final now = DateTime.now();
    _nextPrayer = _todaySchedule!.getNextPrayer(now);
    _timeUntilNextPrayer = _todaySchedule!.getTimeUntilNextPrayer(now);

    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
    });
  }

  Future<void> setCalculationMethod(int method) async {
    _calculationMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCalculationMethod, method);

    if (_currentLocation != null) {
      await loadTodayPrayerTimes();
    }
  }

  double? getQiblaDirection() {
    if (_currentLocation == null) return null;
    return _locationService.calculateQiblaDirection(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
