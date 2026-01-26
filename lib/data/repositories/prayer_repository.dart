import 'package:adhan/adhan.dart' as adhan;
import 'package:dio/dio.dart';
import '../../domain/entities/daily_prayer_schedule.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/prayer_time.dart';
import '../../core/constants/app_constants.dart';

class PrayerRepository {
  final Dio _dio;

  PrayerRepository({Dio? dio}) : _dio = dio ?? Dio();

  DailyPrayerSchedule calculatePrayerTimes({
    required Location location,
    required DateTime date,
    int method = AppConstants.defaultCalculationMethod,
  }) {
    final coordinates = adhan.Coordinates(location.latitude, location.longitude);
    final params = _getCalculationParameters(method);
    final prayerTimes = adhan.PrayerTimes(coordinates, adhan.DateComponents.from(date), params);

    return DailyPrayerSchedule(
      date: date,
      location: location,
      fajr: PrayerTime(name: AppConstants.fajr, time: prayerTimes.fajr),
      sunrise: PrayerTime(name: AppConstants.sunrise, time: prayerTimes.sunrise),
      dhuhr: PrayerTime(name: AppConstants.dhuhr, time: prayerTimes.dhuhr),
      asr: PrayerTime(name: AppConstants.asr, time: prayerTimes.asr),
      maghrib: PrayerTime(name: AppConstants.maghrib, time: prayerTimes.maghrib),
      isha: PrayerTime(name: AppConstants.isha, time: prayerTimes.isha),
    );
  }

  adhan.CalculationParameters _getCalculationParameters(int method) {
    switch (method) {
      case 1:
        return adhan.CalculationMethod.karachi.getParameters();
      case 2:
        return adhan.CalculationMethod.north_america.getParameters();
      case 3:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case 4:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 5:
        return adhan.CalculationMethod.egyptian.getParameters();
      case 11:
        return adhan.CalculationMethod.singapore.getParameters();
      case 13:
        return adhan.CalculationMethod.turkey.getParameters();
      case 15:
        return adhan.CalculationMethod.moon_sighting_committee.getParameters();
      default:
        return adhan.CalculationMethod.singapore.getParameters();
    }
  }

  Future<DailyPrayerSchedule?> fetchPrayerTimesFromApi({
    required Location location,
    required DateTime date,
    int method = AppConstants.defaultCalculationMethod,
  }) async {
    try {
      final formattedDate =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

      final response = await _dio.get(
        '${AppConstants.aladhanBaseUrl}/timings/$formattedDate',
        queryParameters: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'method': method,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final timings = data['data']['timings'];
        final hijri = data['data']['date']['hijri'];

        return DailyPrayerSchedule(
          date: date,
          location: location,
          fajr: _parseApiTime(timings['Fajr'], AppConstants.fajr, date),
          sunrise: _parseApiTime(timings['Sunrise'], AppConstants.sunrise, date),
          dhuhr: _parseApiTime(timings['Dhuhr'], AppConstants.dhuhr, date),
          asr: _parseApiTime(timings['Asr'], AppConstants.asr, date),
          maghrib: _parseApiTime(timings['Maghrib'], AppConstants.maghrib, date),
          isha: _parseApiTime(timings['Isha'], AppConstants.isha, date),
          hijriDay: int.tryParse(hijri['day'].toString()),
          hijriMonth: int.tryParse(hijri['month']['number'].toString()),
          hijriYear: int.tryParse(hijri['year'].toString()),
          hijriMonthName: hijri['month']['en'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  PrayerTime _parseApiTime(String timeStr, String name, DateTime date) {
    final time = timeStr.split(' ')[0];
    final parts = time.split(':');
    return PrayerTime(
      name: name,
      time: DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1])),
    );
  }

  List<DailyPrayerSchedule> calculateWeeklyPrayerTimes({
    required Location location,
    required DateTime startDate,
    int method = AppConstants.defaultCalculationMethod,
  }) {
    final schedules = <DailyPrayerSchedule>[];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      schedules.add(calculatePrayerTimes(location: location, date: date, method: method));
    }
    return schedules;
  }
}
