import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/prayer_time.dart';

enum PrayerStatus { passed, active, upcoming }

class PrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final PrayerStatus status;
  final VoidCallback? onTap;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: status == PrayerStatus.active ? 4 : 2,
      color: _getBackgroundColor(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPrayerIcon(),
                  color: _getIconColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                      ),
                    ),
                    if (status == PrayerStatus.active)
                      Text(
                        'Waktu sholat sekarang',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSubtitleColor(),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                AppDateUtils.formatTime(prayer.time),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              if (status == PrayerStatus.upcoming) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.upcomingPrayer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Berikutnya',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.upcomingPrayer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case PrayerStatus.active:
        return AppColors.activePrayer;
      case PrayerStatus.upcoming:
        return AppColors.surface;
      case PrayerStatus.passed:
        return AppColors.surface.withValues(alpha: 0.7);
    }
  }

  Color _getIconBackgroundColor() {
    switch (status) {
      case PrayerStatus.active:
        return AppColors.surface.withValues(alpha: 0.2);
      case PrayerStatus.upcoming:
        return AppColors.upcomingPrayer.withValues(alpha: 0.1);
      case PrayerStatus.passed:
        return AppColors.passedPrayer.withValues(alpha: 0.1);
    }
  }

  Color _getIconColor() {
    switch (status) {
      case PrayerStatus.active:
        return AppColors.surface;
      case PrayerStatus.upcoming:
        return AppColors.upcomingPrayer;
      case PrayerStatus.passed:
        return AppColors.passedPrayer;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case PrayerStatus.active:
        return AppColors.textOnPrimary;
      case PrayerStatus.upcoming:
        return AppColors.textPrimary;
      case PrayerStatus.passed:
        return AppColors.passedPrayer;
    }
  }

  Color _getSubtitleColor() {
    switch (status) {
      case PrayerStatus.active:
        return AppColors.textOnPrimary.withValues(alpha: 0.8);
      case PrayerStatus.upcoming:
        return AppColors.textSecondary;
      case PrayerStatus.passed:
        return AppColors.passedPrayer;
    }
  }

  IconData _getPrayerIcon() {
    switch (prayer.name) {
      case 'Subuh':
        return Icons.wb_twilight;
      case 'Syuruq':
        return Icons.wb_sunny_outlined;
      case 'Dzuhur':
        return Icons.wb_sunny;
      case 'Ashar':
        return Icons.sunny_snowing;
      case 'Maghrib':
        return Icons.nights_stay_outlined;
      case 'Isya':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }
}
