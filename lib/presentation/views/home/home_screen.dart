import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/prayer_time.dart';
import '../../../domain/entities/daily_prayer_schedule.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/countdown_widget.dart';
import '../../widgets/prayer_card.dart';
import '../qibla/qibla_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('KeSholat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            onPressed: () => _navigateToQibla(context),
            tooltip: 'Kompas Kiblat',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.todaySchedule == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.currentLocation == null) {
            return _buildNoLocationView(context, provider);
          }

          if (provider.error != null && provider.todaySchedule == null) {
            return _buildErrorView(context, provider);
          }

          return _buildPrayerTimesView(context, provider);
        },
      ),
    );
  }

  Widget _buildNoLocationView(BuildContext context, PrayerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Lokasi Belum Diatur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Atur lokasi Anda untuk melihat jadwal waktu sholat yang akurat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.getCurrentLocation(),
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                provider.isLoading ? 'Mencari lokasi...' : 'Gunakan Lokasi Saat Ini',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, PrayerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.getCurrentLocation(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesView(BuildContext context, PrayerProvider provider) {
    final schedule = provider.todaySchedule!;
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () => provider.loadTodayPrayerTimes(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location info
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider.currentLocation?.displayName ?? 'Lokasi tidak diketahui',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => provider.getCurrentLocation(),
                  tooltip: 'Perbarui lokasi',
                ),
              ],
            ),

            // Date
            Text(
              AppDateUtils.formatDate(now),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Countdown to next prayer
            CountdownWidget(
              nextPrayer: provider.nextPrayer,
              timeUntil: provider.timeUntilNextPrayer,
            ),
            const SizedBox(height: 24),

            // Prayer times list
            const Text(
              'Jadwal Sholat Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...schedule.mainPrayers.map((prayer) {
              final status = _getPrayerStatus(prayer, schedule, now);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PrayerCard(
                  prayer: prayer,
                  status: status,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  PrayerStatus _getPrayerStatus(PrayerTime prayer, DailyPrayerSchedule schedule, DateTime now) {
    final nextPrayer = schedule.getNextPrayer(now);
    final currentPrayer = schedule.getCurrentPrayer(now);

    if (currentPrayer?.name == prayer.name) {
      return PrayerStatus.active;
    } else if (nextPrayer?.name == prayer.name) {
      return PrayerStatus.upcoming;
    } else if (prayer.time.isBefore(now)) {
      return PrayerStatus.passed;
    }
    return PrayerStatus.upcoming;
  }

  void _navigateToQibla(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QiblaScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}
