import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  String? _lastError;
  bool _isInitialized = false;

  bool get isPlaying => _isPlaying;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _audioPlayer = AudioPlayer();

    _audioPlayer!.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      debugPrint('AdhanAudioService: Player state changed - playing: $_isPlaying');
    });

    _audioPlayer!.processingStateStream.listen((state) {
      debugPrint('AdhanAudioService: Processing state: $state');
      if (state == ProcessingState.completed) {
        _isPlaying = false;
      }
    });

    _isInitialized = true;
    debugPrint('AdhanAudioService: Initialized');
  }

  Future<bool> isAdhanFileAvailable() async {
    try {
      final assetPath = 'assets/audio/${AppConstants.adhanFile}';
      debugPrint('AdhanAudioService: Checking file availability: $assetPath');
      await rootBundle.load(assetPath);
      debugPrint('AdhanAudioService: File is available');
      return true;
    } catch (e) {
      debugPrint('AdhanAudioService: File not available - $e');
      return false;
    }
  }

  Future<bool> playAdhan({String? adhanFile}) async {
    try {
      _lastError = null;

      // Ensure initialized
      if (!_isInitialized || _audioPlayer == null) {
        debugPrint('AdhanAudioService: Not initialized, initializing now...');
        await initialize();
      }

      final filename = adhanFile ?? AppConstants.adhanFile;
      final assetPath = 'assets/audio/$filename';

      debugPrint('AdhanAudioService: Attempting to play: $assetPath');

      // Check if file exists
      final isAvailable = await isAdhanFileAvailable();
      if (!isAvailable) {
        _lastError = 'File audio adzan tidak ditemukan: $filename\n'
            'Silakan tambahkan file audio ke folder assets/audio/';
        _isPlaying = false;
        debugPrint('AdhanAudioService: $_lastError');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;

      debugPrint('AdhanAudioService: Setting volume to $volume');
      await _audioPlayer!.setVolume(volume);

      debugPrint('AdhanAudioService: Loading asset...');
      await _audioPlayer!.setAsset(assetPath);

      debugPrint('AdhanAudioService: Playing...');
      await _audioPlayer!.play();

      _isPlaying = true;
      debugPrint('AdhanAudioService: Play started successfully');
      return true;
    } catch (e, stackTrace) {
      _lastError = 'Gagal memutar adzan: $e';
      _isPlaying = false;
      debugPrint('AdhanAudioService: Error - $_lastError');
      debugPrint('AdhanAudioService: Stack trace - $stackTrace');
      return false;
    }
  }

  Future<void> stopAdhan() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
    _isPlaying = false;
    debugPrint('AdhanAudioService: Stopped');
  }

  Future<void> pauseAdhan() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.pause();
    }
  }

  Future<void> resumeAdhan() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.play();
    }
  }

  Future<void> setVolume(double volume) async {
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(volume.clamp(0.0, 1.0));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyAdhanVolume, volume);
  }

  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
  }

  Stream<Duration>? get positionStream => _audioPlayer?.positionStream;
  Stream<Duration?>? get durationStream => _audioPlayer?.durationStream;
  Stream<PlayerState>? get playerStateStream => _audioPlayer?.playerStateStream;

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isInitialized = false;
  }
}
