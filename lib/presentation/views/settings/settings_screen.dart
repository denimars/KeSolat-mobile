import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/prayer_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Consumer2<SettingsProvider, PrayerProvider>(
        builder: (context, settings, prayer, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Location section
              _buildSectionTitle('Lokasi'),
              _buildCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: const Text('Lokasi Saat Ini'),
                    subtitle: Text(
                      prayer.currentLocation?.displayName ?? 'Belum diatur',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => prayer.getCurrentLocation(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Adhan section
              _buildSectionTitle('Adzan'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up, color: AppColors.primary),
                    title: const Text('Putar Adzan Otomatis'),
                    subtitle: const Text('Putar adzan saat waktu sholat tiba'),
                    value: settings.adhanEnabled,
                    onChanged: (value) => settings.setAdhanEnabled(value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.play_circle, color: AppColors.primary),
                    title: const Text('Test Adzan'),
                    subtitle: Text(
                      settings.isAdhanAvailable
                          ? 'Ketuk untuk memutar preview adzan'
                          : 'File adzan.mp3 belum tersedia',
                      style: TextStyle(
                        color: settings.isAdhanAvailable
                            ? AppColors.textSecondary
                            : AppColors.warning,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        settings.isPlaying ? Icons.stop : Icons.play_arrow,
                        color: settings.isAdhanAvailable
                            ? AppColors.primary
                            : AppColors.disabledButton,
                      ),
                      onPressed: settings.isAdhanAvailable
                          ? () async {
                              if (settings.isPlaying) {
                                await settings.stopAdhanPreview();
                              } else {
                                final success = await settings.playAdhanPreview();
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          settings.audioError ?? 'Gagal memutar audio'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.volume_down, color: AppColors.primary),
                    title: const Text('Volume Adzan'),
                    subtitle: Slider(
                      value: settings.adhanVolume,
                      onChanged: (value) => settings.setAdhanVolume(value),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Audio error message
              if (settings.audioError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          settings.audioError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => settings.clearAudioError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Notification section
              _buildSectionTitle('Notifikasi'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications, color: AppColors.primary),
                    title: const Text('Notifikasi Waktu Sholat'),
                    subtitle: const Text('Tampilkan notifikasi saat waktu sholat'),
                    value: settings.notificationEnabled,
                    onChanged: (value) => settings.setNotificationEnabled(value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calculation method section
              _buildSectionTitle('Metode Perhitungan'),
              _buildCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calculate, color: AppColors.primary),
                    title: const Text('Metode Perhitungan'),
                    subtitle: Text(
                      AppConstants.calculationMethods[settings.calculationMethod] ??
                          'Tidak diketahui',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCalculationMethodPicker(context, settings, prayer),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Alarm section
              _buildSectionTitle('Alarm Waktu Sholat'),
              _buildCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.alarm, color: AppColors.primary),
                    title: const Text('Aktifkan Alarm Adzan'),
                    subtitle: Text(
                      settings.isBackgroundServiceRunning
                          ? 'Aktif - adzan akan berbunyi saat waktu sholat'
                          : 'Nonaktif - alarm tidak dijadwalkan',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    value: settings.isBackgroundServiceRunning,
                    onChanged: (_) => settings.toggleBackgroundService(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About section
              _buildSectionTitle('Tentang'),
              _buildCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('Versi Aplikasi'),
                    subtitle: const Text(
                      AppConstants.appVersion,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.mosque, color: AppColors.primary),
                    title: Text(AppConstants.appName),
                    subtitle: Text(
                      'Aplikasi jadwal sholat dengan adzan otomatis',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  void _showCalculationMethodPicker(
    BuildContext context,
    SettingsProvider settings,
    PrayerProvider prayer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Metode Perhitungan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: AppConstants.calculationMethods.entries.map((entry) {
                      final isSelected = settings.calculationMethod == entry.key;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        title: Text(entry.value),
                        onTap: () {
                          settings.setCalculationMethod(entry.key);
                          prayer.setCalculationMethod(entry.key);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
