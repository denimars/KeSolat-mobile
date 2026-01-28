import 'package:adhan/adhan.dart' as adhan;
import '../../domain/entities/daily_prayer_schedule.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/prayer_time.dart';
import '../../core/constants/app_constants.dart';

class PrayerRepository {
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
}
