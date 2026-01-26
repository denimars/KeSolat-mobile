import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/qibla_provider.dart';
import '../../widgets/qibla_compass.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QiblaProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kompas Kiblat'),
        actions: [
          Consumer<QiblaProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading
                    ? null
                    : () => provider.refreshLocation(),
                tooltip: 'Perbarui lokasi',
              );
            },
          ),
        ],
      ),
      body: Consumer<QiblaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Mencari lokasi...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
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
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.refreshLocation(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!provider.isCompassAvailable) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.explore_off,
                      size: 64,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kompas Tidak Tersedia',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Perangkat Anda tidak mendukung sensor kompas atau sensor tidak dapat diakses.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (provider.qiblaDirection != null)
                      Text(
                        'Arah Kiblat: ${provider.qiblaDirection!.toStringAsFixed(1)}° dari utara',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Location info
                if (provider.currentLocation != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.currentLocation!.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${provider.currentLocation!.latitude.toStringAsFixed(4)}, ${provider.currentLocation!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Compass
                QiblaCompass(
                  compassHeading: provider.compassHeading,
                  qiblaDirection: provider.qiblaDirection,
                ),
                const SizedBox(height: 32),

                // Direction info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mosque,
                        color: AppColors.textOnAccent,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Arah Kiblat',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textOnAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.qiblaDirection?.toStringAsFixed(1) ?? '-'}°',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnAccent,
                        ),
                      ),
                      const Text(
                        'dari Utara',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textOnAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Compass heading
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.explore,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Heading: ${provider.compassHeading?.toStringAsFixed(1) ?? '-'}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Calibration tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Untuk akurasi terbaik, kalibrasi kompas dengan menggerakkan ponsel membentuk angka 8.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
