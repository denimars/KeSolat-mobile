import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../domain/entities/location.dart' as app;

class LocationService {
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<app.Location?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city;
      String? country;
      String? address;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.locality ?? placemark.subAdministrativeArea;
        country = placemark.country;
        address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      return app.Location(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        address: address,
      );
    } catch (e) {
      return null;
    }
  }

  Future<app.Location?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      String? city;
      String? country;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.locality ?? placemark.subAdministrativeArea;
        country = placemark.country;
      }

      return app.Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );
    } catch (e) {
      return app.Location(
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  double calculateQiblaDirection(double latitude, double longitude) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;

    final latRad = latitude * (math.pi / 180);
    final lngRad = longitude * (math.pi / 180);
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
}
