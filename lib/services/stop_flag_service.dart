import 'dart:io';
import 'package:flutter/widgets.dart';

/// Service untuk komunikasi stop flag antar isolate menggunakan file
/// Menggunakan path yang PASTI sama di semua isolate
class StopFlagService {
  static const String _stopFileName = 'kesholat_stop.flag';
  static const String _playingFileName = 'kesholat_playing.flag';

  /// Get the app's private data directory path
  /// This is accessible from both main isolate and background isolates
  static String _getBasePath() {
    if (Platform.isAndroid) {
      // Try multiple possible paths for compatibility across devices
      // Most devices use /data/user/0, but some use /data/data
      final paths = [
        '/data/user/0/com.kesholat.app/files',
        '/data/data/com.kesholat.app/files',
      ];

      for (final path in paths) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          return path;
        }
      }

      // Default to most common path
      return '/data/user/0/com.kesholat.app/files';
    }
    return Directory.systemTemp.path;
  }

  /// Ensure base directory exists
  static Future<void> _ensureDirectoryExists() async {
    final dir = Directory(_getBasePath());
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        debugPrint('StopFlagService: Error creating directory: $e');
      }
    }
  }

  static String _getStopFlagPath() {
    return '${_getBasePath()}/$_stopFileName';
  }

  static String _getPlayingFlagPath() {
    return '${_getBasePath()}/$_playingFileName';
  }

  /// Set stop requested flag
  static Future<void> setStopRequested(bool value) async {
    await _ensureDirectoryExists();
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
    await _ensureDirectoryExists();
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
