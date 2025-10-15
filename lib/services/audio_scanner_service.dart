import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_folder.dart';

class AudioScannerService {
  static const String _cachedDirKey = 'last_scanned_directory';
  static const String _cachedFilesKey = 'cached_audio_files';
  static const String _lastScanTimeKey = 'last_scan_timestamp';
  static const Duration _cacheDuration = Duration(days: 7);

  /// Checks if the cache is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScanTime = prefs.getInt(_lastScanTimeKey) ?? 0;
      return DateTime.now().millisecondsSinceEpoch - lastScanTime <
          _cacheDuration.inMilliseconds;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking cache validity: $e');
      }
      return false;
    }
  }

  /// Saves the directory path and files to cache
  Future<void> _saveToCache(String directoryPath, List<File> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedDirKey, directoryPath);
      await prefs.setStringList(
        _cachedFilesKey,
        files.map((file) => file.path).toList(),
      );
      await prefs.setInt(
        _lastScanTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to cache: $e');
      }
    }
  }

  /// Gets cached files if available and valid
  Future<List<File>?> _getCachedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directoryPath = prefs.getString(_cachedDirKey);
      final filePaths = prefs.getStringList(_cachedFilesKey);

      if (directoryPath != null && filePaths != null) {
        // Check if all files still exist
        final files = filePaths
            .map((path) => File(path))
            .where((file) => file.existsSync())
            .toList();
        if (files.isNotEmpty) {
          return files;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached files: $e');
      }
    }
    return null;
  }

  /// Request storage permissions based on Android version
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ requires READ_MEDIA_AUDIO
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.audio.request();
        return status.isGranted;
      } else {
        // Android 12 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // For other platforms
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    try {
      // This is a simple check, you can use device_info_plus for more accurate detection
      return 33; // Assume Android 13+ for safety
    } catch (e) {
      return 33;
    }
  }

  /// Scans the device for audio files
  Future<List<File>> scanForAudioFiles() async {
    try {
      // Check cache first
      final isCacheValid = await _isCacheValid();
      if (isCacheValid) {
        final cachedFiles = await _getCachedFiles();
        if (cachedFiles != null && cachedFiles.isNotEmpty) {
          return cachedFiles;
        }
      }

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (hasPermission) {
        // Let user select a directory to scan
        final directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath != null) {
          final files = await _findAudioFiles(Directory(directoryPath));
          // Save to cache
          await _saveToCache(directoryPath, files);
          return files;
        }
      } else {
        throw Exception(
          'Storage permission is required to scan for audio files',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning for audio files: $e');
      }
      rethrow;
    }
    return [];
  }

  /// Recursively finds audio files in a directory
  Future<List<File>> _findAudioFiles(Directory directory) async {
    final List<File> audioFiles = [];
    try {
      await for (var entity in directory.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.endsWith('.mp3') ||
              path.endsWith('.wav') ||
              path.endsWith('.m4a') ||
              path.endsWith('.aac') ||
              path.endsWith('.ogg')) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }
    return audioFiles;
  }

  /// Scans for folders containing audio files
  Future<List<AudioFolder>> scanForAudioFolders() async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (hasPermission) {
        // Let user select a directory to scan
        final directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath != null) {
          final folders = await _findAudioFolders(Directory(directoryPath));
          return folders;
        }
      } else {
        throw Exception(
          'Storage permission is required to scan for audio folders',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning for audio folders: $e');
      }
      rethrow;
    }
    return [];
  }

  /// Auto scans common directories for audio folders
  Future<List<AudioFolder>> autoScanForAudioFolders() async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Storage permission not granted');
        }
        return [];
      }

      final List<AudioFolder> allFolders = [];
      
      // Common music directories to scan
      final List<String> commonPaths = [
        Platform.environment['USERPROFILE'] ?? '',
        Platform.environment['HOME'] ?? '',
      ];

      for (final basePath in commonPaths) {
        if (basePath.isEmpty) continue;

        final musicDirs = [
          '$basePath${Platform.pathSeparator}Music',
          '$basePath${Platform.pathSeparator}Downloads',
          '$basePath${Platform.pathSeparator}Documents${Platform.pathSeparator}Music',
        ];

        for (final dirPath in musicDirs) {
          final directory = Directory(dirPath);
          if (await directory.exists()) {
            try {
              final folders = await _findAudioFolders(directory);
              allFolders.addAll(folders);
            } catch (e) {
              if (kDebugMode) {
                print('Error scanning $dirPath: $e');
              }
            }
          }
        }
      }

      // Remove duplicates based on path
      final uniqueFolders = <String, AudioFolder>{};
      for (final folder in allFolders) {
        if (!uniqueFolders.containsKey(folder.path)) {
          uniqueFolders[folder.path] = folder;
        }
      }

      final result = uniqueFolders.values.toList();
      result.sort((a, b) => b.songCount.compareTo(a.songCount));
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error auto scanning for audio folders: $e');
      }
      return [];
    }
  }

  /// Finds folders containing audio files
  Future<List<AudioFolder>> _findAudioFolders(Directory directory) async {
    final Map<String, int> folderSongCount = {};
    
    try {
      await for (var entity in directory.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.endsWith('.mp3') ||
              path.endsWith('.wav') ||
              path.endsWith('.m4a') ||
              path.endsWith('.aac') ||
              path.endsWith('.ogg')) {
            // Get the parent directory of the audio file
            final parentPath = entity.parent.path;
            folderSongCount[parentPath] = (folderSongCount[parentPath] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }

    // Convert map to list of AudioFolder objects
    final folders = folderSongCount.entries.map((entry) {
      return AudioFolder(
        path: entry.key,
        name: AudioFolder.getFolderName(entry.key),
        songCount: entry.value,
      );
    }).toList();

    // Sort by song count (descending)
    folders.sort((a, b) => b.songCount.compareTo(a.songCount));

    return folders;
  }

  /// Get audio files from a specific folder
  Future<List<File>> getAudioFilesFromFolder(String folderPath) async {
    final List<File> audioFiles = [];
    try {
      final directory = Directory(folderPath);
      await for (var entity in directory.list(recursive: false)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.endsWith('.mp3') ||
              path.endsWith('.wav') ||
              path.endsWith('.m4a') ||
              path.endsWith('.aac') ||
              path.endsWith('.ogg')) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting audio files from folder $folderPath: $e');
      }
    }
    return audioFiles;
  }
}
