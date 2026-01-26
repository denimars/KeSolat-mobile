import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatDateShort(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  static String formatHijriDate(int day, int month, int year) {
    const hijriMonths = [
      'Muharram',
      'Safar',
      'Rabiul Awal',
      'Rabiul Akhir',
      'Jumadil Awal',
      'Jumadil Akhir',
      'Rajab',
      'Sya\'ban',
      'Ramadhan',
      'Syawal',
      'Dzulqa\'dah',
      'Dzulhijjah',
    ];

    if (month < 1 || month > 12) return '';
    return '$day ${hijriMonths[month - 1]} $year H';
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  static String formatCountdownShort(Duration duration) {
    if (duration.isNegative) return '0 menit';

    if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes % 60} menit';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit';
    } else {
      return '${duration.inSeconds} detik';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
