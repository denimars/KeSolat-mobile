import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/prayer_time.dart';

class CountdownWidget extends StatelessWidget {
  final PrayerTime? nextPrayer;
  final Duration? timeUntil;

  const CountdownWidget({
    super.key,
    required this.nextPrayer,
    required this.timeUntil,
  });

  @override
  Widget build(BuildContext context) {
    if (nextPrayer == null || timeUntil == null) {
      return _buildNoNextPrayer();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Waktu Sholat Berikutnya',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextPrayer!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppDateUtils.formatTime(nextPrayer!.time),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppDateUtils.formatCountdown(timeUntil!),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNextPrayer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.textOnPrimary,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Semua Sholat Hari Ini Selesai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal akan diperbarui besok',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
