import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../services/location_service.dart';
import '../../domain/entities/location.dart';

class QiblaProvider extends ChangeNotifier {
  final LocationService _locationService;

  double? _compassHeading;
  double? _qiblaDirection;
  Location? _currentLocation;
  bool _isCompassAvailable = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<CompassEvent>? _compassSubscription;

  QiblaProvider({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  double? get compassHeading => _compassHeading;
  double? get qiblaDirection => _qiblaDirection;
  Location? get currentLocation => _currentLocation;
  bool get isCompassAvailable => _isCompassAvailable;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double? get qiblaFromNorth {
    if (_qiblaDirection == null || _compassHeading == null) return null;
    return (_qiblaDirection! - _compassHeading! + 360) % 360;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isCompassAvailable = (await FlutterCompass.events?.first) != null;
    } catch (e) {
      _isCompassAvailable = false;
    }

    await _getCurrentLocation();
    _startCompassListener();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        _qiblaDirection = _locationService.calculateQiblaDirection(
          location.latitude,
          location.longitude,
        );
        _error = null;
      } else {
        _error = 'Gagal mendapatkan lokasi';
      }
    } catch (e) {
      _error = 'Error mendapatkan lokasi: $e';
    }
    notifyListeners();
  }

  void _startCompassListener() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      _compassHeading = event.heading;
      notifyListeners();
    });
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _getCurrentLocation();

    _isLoading = false;
    notifyListeners();
  }

  void setLocation(Location location) {
    _currentLocation = location;
    _qiblaDirection = _locationService.calculateQiblaDirection(
      location.latitude,
      location.longitude,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
