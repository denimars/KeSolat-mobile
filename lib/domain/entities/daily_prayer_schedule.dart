import 'prayer_time.dart';
import 'location.dart';

class DailyPrayerSchedule {
  final DateTime date;
  final Location location;
  final PrayerTime fajr;
  final PrayerTime sunrise;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;
  final int? hijriDay;
  final int? hijriMonth;
  final int? hijriYear;
  final String? hijriMonthName;

  const DailyPrayerSchedule({
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

  List<PrayerTime> get allPrayers => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  List<PrayerTime> get mainPrayers => [fajr, dhuhr, asr, maghrib, isha];

  PrayerTime? getNextPrayer(DateTime now) {
    for (final prayer in mainPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  PrayerTime? getCurrentPrayer(DateTime now) {
    PrayerTime? current;
    for (final prayer in mainPrayers) {
      if (prayer.time.isBefore(now) || prayer.time.isAtSameMomentAs(now)) {
        current = prayer;
      } else {
        break;
      }
    }
    return current;
  }

  Duration? getTimeUntilNextPrayer(DateTime now) {
    final next = getNextPrayer(now);
    if (next == null) return null;
    return next.time.difference(now);
  }

  @override
  String toString() =>
      'DailyPrayerSchedule(date: $date, fajr: ${fajr.time}, dhuhr: ${dhuhr.time})';
}
