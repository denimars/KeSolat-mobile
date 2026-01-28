class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'KeSholat';
  static const String appVersion = '1.0.0';

  // Prayer Names
  static const String fajr = 'Subuh';
  static const String sunrise = 'Syuruq';
  static const String dhuhr = 'Dzuhur';
  static const String asr = 'Ashar';
  static const String maghrib = 'Maghrib';
  static const String isha = 'Isya';

  // Kaaba Coordinates (for Qibla calculation)
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  // Notification Channels
  static const String prayerNotificationChannelId = 'prayer_notification';
  static const String prayerNotificationChannelName = 'Prayer Notifications';
  static const String prayerNotificationChannelDesc = 'Notifications for prayer times';

  static const String adhanNotificationChannelId = 'adhan_notification';
  static const String adhanNotificationChannelName = 'Adhan Notifications';
  static const String adhanNotificationChannelDesc = 'Full screen notifications with adhan';

  static const String backgroundServiceChannelId = 'background_service';
  static const String backgroundServiceChannelName = 'Background Service';
  static const String backgroundServiceChannelDesc = 'KeSholat background service';

  // SharedPreferences Keys
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';
  static const String keyCity = 'city';
  static const String keyCountry = 'country';
  static const String keyCalculationMethod = 'calculation_method';
  static const String keyAdhanVolume = 'adhan_volume';
  static const String keyAdhanEnabled = 'adhan_enabled';
  static const String keyNotificationEnabled = 'notification_enabled';

  // Notification IDs
  static const int adhanNotificationId = 999;

  // Adhan Audio File
  static const String adhanFile = 'adzan.mp3';

  // Prayer Calculation Methods
  static const Map<int, String> calculationMethods = {
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America',
    3: 'Muslim World League',
    4: 'Umm Al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    11: 'Majlis Ugama Islam Singapura',
    13: 'Diyanet İşleri Başkanlığı, Turkey',
    15: 'Moonsighting Committee Worldwide',
  };

  // Default calculation method (Singapore/Kemenag RI)
  static const int defaultCalculationMethod = 11;
}
