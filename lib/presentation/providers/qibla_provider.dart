import 'dart:async';
import 'dart:math' as math;
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
        _qiblaDirection = _calculateQiblaDirection(
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

  double _calculateQiblaDirection(double lat, double lng) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;

    final latRad = lat * (math.pi / 180);
    final lngRad = lng * (math.pi / 180);
    final kaabaLatRad = kaabaLat * (math.pi / 180);
    final kaabaLngRad = kaabaLng * (math.pi / 180);

    final deltaLng = kaabaLngRad - lngRad;

    final y = math.sin(deltaLng);
    final x = math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(deltaLng);

    var qibla = math.atan2(y, x) * (180 / math.pi);

    if (qibla < 0) {
      qibla += 360;
    }

    return qibla;
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
    _qiblaDirection = _calculateQiblaDirection(
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
