class Location {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? address;

  const Location({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.address,
  });

  Location copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? address,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
    );
  }

  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (address != null) {
      return address!;
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'Location(lat: $latitude, lng: $longitude, city: $city)';
}
