class PrayerTime {
  final String name;
  final DateTime time;
  final bool isNotificationEnabled;

  const PrayerTime({
    required this.name,
    required this.time,
    this.isNotificationEnabled = true,
  });

  PrayerTime copyWith({
    String? name,
    DateTime? time,
    bool? isNotificationEnabled,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTime &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          time == other.time;

  @override
  int get hashCode => name.hashCode ^ time.hashCode;

  @override
  String toString() => 'PrayerTime(name: $name, time: $time)';
}
