import 'dart:io';
import 'package:flutter/widgets.dart';

/// Service untuk komunikasi stop flag antar isolate menggunakan file
/// Menggunakan path yang PASTI sama di semua isolate
class StopFlagService {
  static const String _stopFileName = 'kesholat_stop.flag';
  static const String _playingFileName = 'kesholat_playing.flag';

  /// Get a path that is GUARANTEED to be the same in all isolates
  /// Using /data/local/tmp which is accessible to all processes
  static String _getBasePath() {
    // Use /data/local/tmp which is world-readable/writable on Android
    if (Platform.isAndroid) {
      return '/data/local/tmp';
    }
    return Directory.systemTemp.path;
  }

  static String _getStopFlagPath() {
    return '${_getBasePath()}/$_stopFileName';
  }

  static String _getPlayingFlagPath() {
    return '${_getBasePath()}/$_playingFileName';
  }

  /// Set stop requested flag
  static Future<void> setStopRequested(bool value) async {
    final path = _getStopFlagPath();
    debugPrint('StopFlagService: setStopRequested($value) at $path');
    try {
      final file = File(path);
      if (value) {
        await file.writeAsString('STOP');
        debugPrint('StopFlagService: *** STOP FLAG FILE CREATED ***');

        // Verify it was created
        final exists = await file.exists();
        debugPrint('StopFlagService: File exists after create: $exists');
      } else {
        if (await file.exists()) {
          await file.delete();
          debugPrint('StopFlagService: Stop flag DELETED');
        }
      }
    } catch (e) {
      debugPrint('StopFlagService: ERROR setting stop flag: $e');
    }
  }

  /// Check if stop is requested - SYNCHRONOUS version for reliability
  static bool isStopRequestedSync() {
    try {
      final file = File(_getStopFlagPath());
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Check if stop is requested
  static Future<bool> isStopRequested() async {
    try {
      final path = _getStopFlagPath();
      final file = File(path);
      final exists = await file.exists();
      return exists;
    } catch (e) {
      debugPrint('StopFlagService: Error checking stop flag: $e');
      return false;
    }
  }

  /// Set playing flag
  static Future<void> setPlaying(bool value) async {
    final path = _getPlayingFlagPath();
    try {
      final file = File(path);
      if (value) {
        await file.writeAsString('PLAYING');
        debugPrint('StopFlagService: Playing flag CREATED at $path');
      } else {
        if (await file.exists()) {
          await file.delete();
          debugPrint('StopFlagService: Playing flag DELETED');
        }
      }
    } catch (e) {
      debugPrint('StopFlagService: Error setting playing flag: $e');
    }
  }

  /// Check if adhan is playing - SYNCHRONOUS version
  static bool isPlayingSync() {
    try {
      final file = File(_getPlayingFlagPath());
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Check if adhan is playing
  static Future<bool> isPlaying() async {
    try {
      final file = File(_getPlayingFlagPath());
      return await file.exists();
    } catch (e) {
      debugPrint('StopFlagService: Error checking playing flag: $e');
      return false;
    }
  }

  /// Clear all flags
  static Future<void> clearAllFlags() async {
    await setStopRequested(false);
    await setPlaying(false);
  }

  /// Get the stop flag file path (for debugging)
  static Future<String> getStopFlagFilePath() async {
    return _getStopFlagPath();
  }
}
