import '../../domain/entities/prayer_time.dart';

class PrayerTimeModel {
  final String name;
  final DateTime time;
  final bool isNotificationEnabled;

  PrayerTimeModel({
    required this.name,
    required this.time,
    this.isNotificationEnabled = true,
  });

  factory PrayerTimeModel.fromEntity(PrayerTime entity) {
    return PrayerTimeModel(
      name: entity.name,
      time: entity.time,
      isNotificationEnabled: entity.isNotificationEnabled,
    );
  }

  PrayerTime toEntity() {
    return PrayerTime(
      name: name,
      time: time,
      isNotificationEnabled: isNotificationEnabled,
    );
  }

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json, String name, DateTime date) {
    final timeString = json[name.toLowerCase()] as String;
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1].split(' ')[0]);

    return PrayerTimeModel(
      name: name,
      time: DateTime(date.year, date.month, date.day, hour, minute),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time': time.toIso8601String(),
      'isNotificationEnabled': isNotificationEnabled,
    };
  }
}
