import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Audio handler for background audio playback
class AdhanAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AdhanAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await stop();
        // Clear the cross-isolate playing flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('adhan_is_playing', false);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.pause,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.pause,
        MediaAction.stop,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  Future<void> playFromAsset(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await play();
    } catch (e) {
      debugPrint('AdhanAudioHandler: Error playing from asset: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume);
}

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  static AdhanAudioHandler? _audioHandler;
  AudioPlayer? _fallbackPlayer;
  bool _isPlaying = false;
  String? _lastError;
  bool _isInitialized = false;

  bool get isPlaying => _isPlaying;
  String? get lastError => _lastError;

  static AdhanAudioHandler? get audioHandler => _audioHandler;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to initialize audio_service for background playback
      _audioHandler = await AudioService.init(
        builder: () => AdhanAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.kesholat.app.adhan',
          androidNotificationChannelName: 'Adhan Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      debugPrint('AdhanAudioService: AudioService initialized');
    } catch (e) {
      debugPrint('AdhanAudioService: AudioService init failed, using fallback: $e');
      // Fallback to direct AudioPlayer for preview/testing
      _fallbackPlayer = AudioPlayer();
      _fallbackPlayer!.processingStateStream.listen((state) async {
        if (state == ProcessingState.completed) {
          _isPlaying = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('adhan_is_playing', false);
        }
      });
    }

    _isInitialized = true;
    debugPrint('AdhanAudioService: Initialized');
  }

  bool? _cachedFileAvailable;

  Future<bool> isAdhanFileAvailable() async {
    // Return cached result to avoid repeated heavy loads
    if (_cachedFileAvailable != null) return _cachedFileAvailable!;

    try {
      final assetPath = 'assets/audio/${AppConstants.adhanFile}';
      // Use loadString with a small test instead of loading entire file
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      _cachedFileAvailable = manifestContent.contains(assetPath);
      debugPrint('AdhanAudioService: File available: $_cachedFileAvailable');
      return _cachedFileAvailable!;
    } catch (e) {
      debugPrint('AdhanAudioService: File check error - $e');
      _cachedFileAvailable = false;
      return false;
    }
  }

  Future<bool> playAdhan({String? adhanFile}) async {
    try {
      _lastError = null;

      // Check if already playing (local state)
      if (_isPlaying) {
        debugPrint('AdhanAudioService: Already playing (local state), skipping');
        return true;
      }

      // Check if already playing (cross-isolate check)
      final prefs = await SharedPreferences.getInstance();
      final isGloballyPlaying = prefs.getBool('adhan_is_playing') ?? false;
      if (isGloballyPlaying) {
        debugPrint('AdhanAudioService: Already playing (global state), skipping');
        return true;
      }

      // Ensure initialized
      if (!_isInitialized) {
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

      final volume = prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;

      // Use audio handler if available (for background playback)
      if (_audioHandler != null) {
        debugPrint('AdhanAudioService: Using AudioService for playback');
        await _audioHandler!.setVolume(volume);
        await _audioHandler!.playFromAsset(assetPath);
      } else if (_fallbackPlayer != null) {
        debugPrint('AdhanAudioService: Using fallback player');
        await _fallbackPlayer!.setVolume(volume);
        await _fallbackPlayer!.setAsset(assetPath);
        await _fallbackPlayer!.play();
      } else {
        throw Exception('No audio player available');
      }

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
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    }
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.stop();
    }
    _isPlaying = false;
    // Clear global playing flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_is_playing', false);
    debugPrint('AdhanAudioService: Stopped');
  }

  Future<void> pauseAdhan() async {
    if (_audioHandler != null) {
      await _audioHandler!.pause();
    }
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.pause();
    }
  }

  Future<void> resumeAdhan() async {
    if (_audioHandler != null) {
      await _audioHandler!.play();
    }
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.play();
    }
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    if (_audioHandler != null) {
      await _audioHandler!.setVolume(clampedVolume);
    }
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.setVolume(clampedVolume);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyAdhanVolume, clampedVolume);
  }

  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.keyAdhanVolume) ?? 1.0;
  }

  void dispose() {
    _fallbackPlayer?.dispose();
    _fallbackPlayer = null;
    _isInitialized = false;
  }
}