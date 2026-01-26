import '../../domain/entities/daily_prayer_schedule.dart';
import 'prayer_time_model.dart';
import 'location_model.dart';

class DailyPrayerScheduleModel {
  final DateTime date;
  final LocationModel location;
  final PrayerTimeModel fajr;
  final PrayerTimeModel sunrise;
  final PrayerTimeModel dhuhr;
  final PrayerTimeModel asr;
  final PrayerTimeModel maghrib;
  final PrayerTimeModel isha;
  final int? hijriDay;
  final int? hijriMonth;
  final int? hijriYear;
  final String? hijriMonthName;

  DailyPrayerScheduleModel({
    required this.date,
    required this.location,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.hijriDay,
    this.hijriMonth,
    this.hijriYear,
    this.hijriMonthName,
  });

  factory DailyPrayerScheduleModel.fromEntity(DailyPrayerSchedule entity) {
    return DailyPrayerScheduleModel(
      date: entity.date,
      location: LocationModel.fromEntity(entity.location),
      fajr: PrayerTimeModel.fromEntity(entity.fajr),
      sunrise: PrayerTimeModel.fromEntity(entity.sunrise),
      dhuhr: PrayerTimeModel.fromEntity(entity.dhuhr),
      asr: PrayerTimeModel.fromEntity(entity.asr),
      maghrib: PrayerTimeModel.fromEntity(entity.maghrib),
      isha: PrayerTimeModel.fromEntity(entity.isha),
      hijriDay: entity.hijriDay,
      hijriMonth: entity.hijriMonth,
      hijriYear: entity.hijriYear,
      hijriMonthName: entity.hijriMonthName,
    );
  }

  DailyPrayerSchedule toEntity() {
    return DailyPrayerSchedule(
      date: date,
      location: location.toEntity(),
      fajr: fajr.toEntity(),
      sunrise: sunrise.toEntity(),
      dhuhr: dhuhr.toEntity(),
      asr: asr.toEntity(),
      maghrib: maghrib.toEntity(),
      isha: isha.toEntity(),
      hijriDay: hijriDay,
      hijriMonth: hijriMonth,
      hijriYear: hijriYear,
      hijriMonthName: hijriMonthName,
    );
  }

  factory DailyPrayerScheduleModel.fromApiResponse(
    Map<String, dynamic> json,
    LocationModel location,
  ) {
    final data = json['data'];
    final timings = data['timings'] as Map<String, dynamic>;
    final dateInfo = data['date'];
    final gregorian = dateInfo['gregorian'];
    final hijri = dateInfo['hijri'];

    final date = DateTime.parse(gregorian['date'].toString().split('-').reversed.join('-'));

    return DailyPrayerScheduleModel(
      date: date,
      location: location,
      fajr: _parseTime(timings['Fajr'], 'Subuh', date),
      sunrise: _parseTime(timings['Sunrise'], 'Syuruq', date),
      dhuhr: _parseTime(timings['Dhuhr'], 'Dzuhur', date),
      asr: _parseTime(timings['Asr'], 'Ashar', date),
      maghrib: _parseTime(timings['Maghrib'], 'Maghrib', date),
      isha: _parseTime(timings['Isha'], 'Isya', date),
      hijriDay: int.tryParse(hijri['day'].toString()),
      hijriMonth: int.tryParse(hijri['month']['number'].toString()),
      hijriYear: int.tryParse(hijri['year'].toString()),
      hijriMonthName: hijri['month']['en'] as String?,
    );
  }

  static PrayerTimeModel _parseTime(dynamic timeString, String name, DateTime date) {
    final time = timeString.toString().split(' ')[0];
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return PrayerTimeModel(
      name: name,
      time: DateTime(date.year, date.month, date.day, hour, minute),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'location': location.toJson(),
      'fajr': fajr.toJson(),
      'sunrise': sunrise.toJson(),
      'dhuhr': dhuhr.toJson(),
      'asr': asr.toJson(),
      'maghrib': maghrib.toJson(),
      'isha': isha.toJson(),
      'hijriDay': hijriDay,
      'hijriMonth': hijriMonth,
      'hijriYear': hijriYear,
      'hijriMonthName': hijriMonthName,
    };
  }
}
