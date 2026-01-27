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

  // Kaaba Coordinates
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  // Default Location (Jakarta, Indonesia)
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const String defaultCity = 'Jakarta';
  static const String defaultCountry = 'Indonesia';

  // API
  static const String aladhanBaseUrl = 'https://api.aladhan.com/v1';

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

  // Hive Boxes
  static const String prayerTimesBox = 'prayer_times';
  static const String settingsBox = 'settings';
  static const String locationBox = 'location';

  // SharedPreferences Keys
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';
  static const String keyCity = 'city';
  static const String keyCountry = 'country';
  static const String keyCalculationMethod = 'calculation_method';
  static const String keyAdhanVolume = 'adhan_volume';
  static const String keyAdhanEnabled = 'adhan_enabled';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyFirstLaunch = 'first_launch';

  // Background Service
  static const int prayerCheckIntervalSeconds = 60;
  static const String backgroundServiceNotificationTitle = 'KeSholat';
  static const String backgroundServiceNotificationContent = 'Prayer times monitoring active';

  // Notification IDs
  static const int adhanNotificationId = 999;

  // Adhan Audio File
  static const String adhanFile = 'adzan.mp3';

  // Prayer Calculation Methods
  static const Map<int, String> calculationMethods = {
    0: 'Jafari / Shia Ithna-Ashari',
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America',
    3: 'Muslim World League',
    4: 'Umm Al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    7: 'Institute of Geophysics, University of Tehran',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Majlis Ugama Islam Singapura',
    12: 'Union Organization Islamic de France',
    13: 'Diyanet İşleri Başkanlığı, Turkey',
    14: 'Spiritual Administration of Muslims of Russia',
    15: 'Moonsighting Committee Worldwide',
    99: 'Custom',
  };

  // Default calculation method (Kemenag RI uses similar to method 5 or 11)
  static const int defaultCalculationMethod = 11;
}
