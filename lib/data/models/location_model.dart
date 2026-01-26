import '../../domain/entities/location.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.address,
  });

  factory LocationModel.fromEntity(Location entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      city: entity.city,
      country: entity.country,
      address: entity.address,
    );
  }

  Location toEntity() {
    return Location(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      address: address,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'address': address,
    };
  }
}
