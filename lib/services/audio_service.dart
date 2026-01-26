import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _lastError;

  bool get isPlaying => _isPlaying;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _isPlaying = false;
      }
    });
  }

  Future<bool> isAdhanFileAvailable(String filename) async {
    try {
      await rootBundle.load('assets/audio/$filename');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableAdhanFiles() async {
    final available = <String>[];
    for (final file in AppConstants.adhanOptions) {
      if (await isAdhanFileAvailable(file)) {
        available.add(file);
      }
    }
    return available;
  }

  Future<bool> playAdhan({String? adhanFile}) async {
    try {
      _lastError = null;
      final prefs = await SharedPreferences.getInstance();
      final selectedAdhan = adhanFile ??
          prefs.getString(AppConstants.keySelectedAdhan) ??
          AppConstants.adhanOptions.first;

      // Check if file exists
      final isAvailable = await isAdhanFileAvailable(selectedAdhan);
      if (!isAvailable) {
        _lastError = 'File audio adzan tidak ditemukan: $selectedAdhan\n'
            'Silakan tambahkan file audio ke folder assets/audio/';
        _isPlaying = false;
        return false;
      }

      final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;

      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setAsset('assets/audio/$selectedAdhan');
      await _audioPlayer.play();
      _isPlaying = true;
      return true;
    } catch (e) {
      _lastError = 'Gagal memutar adzan: $e';
      _isPlaying = false;
      return false;
    }
  }

  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  Future<void> pauseAdhan() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeAdhan() async {
    await _audioPlayer.play();
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyAdhanVolume, volume);
  }

  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
  }

  Future<void> setSelectedAdhan(String adhanFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySelectedAdhan, adhanFile);
  }

  Future<String> getSelectedAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keySelectedAdhan) ??
        AppConstants.adhanOptions.first;
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  void dispose() {
    _audioPlayer.dispose();
  }
}
