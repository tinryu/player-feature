import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_folder.dart';

class AudioScannerService {
  static const Duration _cacheDuration = Duration(days: 7);
  static const String _cachedDirKey = 'last_scanned_directory';
  static const String _cachedFilesKey = 'cached_audio_files';
  static const String _lastScanTimeKey = 'last_scan_timestamp';

  static const String _cachedFolderPathKey = 'lastScannedFolderPath';
  static const String _cachedFolderListKey = '${_cachedFolderPathKey}_list';
  static const String _cachedFolderCountsKey = '${_cachedFolderPathKey}_counts';

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

  /// Gets cached files if available and valid
  Future<List<File>?> getCachedFiles() async {
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
    return [];
  }

  Future<List<AudioFolder>> getCachedFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the list of cached folder paths
      final cachedFolderPaths = prefs.getStringList(_cachedFolderListKey) ?? [];
      if (cachedFolderPaths.isEmpty) {
        if (kDebugMode) {
          print('No cached folder paths found');
        }
        return [];
      }

      // Get the cached song counts
      final cachedSongCounts =
          prefs.getStringList(_cachedFolderCountsKey) ?? [];

      if (kDebugMode) {
        print('Retrieved from cache:');
        print('  Folder paths: $cachedFolderPaths');
        print('  Song counts: $cachedSongCounts');
      }

      // Convert paths to AudioFolder objects with their respective song counts
      return List<AudioFolder>.generate(cachedFolderPaths.length, (index) {
        final path = cachedFolderPaths[index];
        final songCount = index < cachedSongCounts.length
            ? int.tryParse(cachedSongCounts[index]) ?? 0
            : 0;

        if (kDebugMode) {
          print('Creating AudioFolder: path=$path, songCount=$songCount');
        }
        return AudioFolder(
          path: path,
          name: AudioFolder.getFolderName(path),
          songCount: songCount,
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached folders: $e');
      }
      return [];
    }
  }

  /// Request storage permissions based on Android version
  /// Clears all cached folder data including paths and song counts
  Future<bool> clearCachedFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedFolderPathKey);
      await prefs.remove(_cachedFolderListKey);
      await prefs.remove(_cachedFolderCountsKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached folders: $e');
      }
      return false;
    }
  }

  Future<bool> clearCachedFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedDirKey);
      await prefs.remove(_cachedFilesKey);
      await prefs.remove(_lastScanTimeKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached files: $e');
      }
      return false;
    }
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
      if (kDebugMode) {
        print('Starting audio file scan...');
      }

      // Check cache first
      final isCacheValid = await _isCacheValid();
      if (isCacheValid) {
        if (kDebugMode) {
          print('Checking cache for audio files...');
        }
        final cachedFiles = await getCachedFiles();
        if (cachedFiles != null && cachedFiles.isNotEmpty) {
          if (kDebugMode) {
            print('Found ${cachedFiles.length} cached audio files');
          }
          return cachedFiles;
        }
      }

      // Request storage permission
      if (kDebugMode) {
        print('Requesting storage permission...');
      }
      final hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        throw Exception(
          'Storage permission is required to scan for audio files',
        );
      }

      if (kDebugMode) {
        print('Permission granted, opening directory picker...');
      }

      // Let user select a directory to scan
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder with music',
      );

      if (directoryPath == null) {
        if (kDebugMode) {
          print('No directory selected');
        }
        return [];
      }

      if (kDebugMode) {
        print('Scanning directory: $directoryPath');
      }

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('Selected directory does not exist');
      }

      final files = await _findAudioFiles(directory);

      if (kDebugMode) {
        print('Found ${files.length} audio files');
      }

      // Save to cache
      await _saveToCache(directoryPath, files);
      return files;
    } catch (e) {
      if (kDebugMode) {
        print('Error in scanForAudioFiles: $e');
        print('Error type: ${e.runtimeType}');
        if (e is Error) {
          print('Stack trace: ${e.stackTrace}');
        }
      }
      rethrow;
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

  Future<void> _saveFoldersToCache(List<AudioFolder> folders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (folders.isNotEmpty) {
        final mainFolderPath = Directory(folders.first.path).parent.path;
        await prefs.setString(_cachedFolderPathKey, mainFolderPath);

        // Save folder paths
        final folderPaths = folders.map((folder) => folder.path).toList();
        await prefs.setStringList(_cachedFolderListKey, folderPaths);

        // Save song counts
        final songCounts = folders
            .map((folder) => folder.songCount.toString())
            .toList();
        await prefs.setStringList(_cachedFolderCountsKey, songCounts);

        if (kDebugMode) {
          print('Saved to cache:');
          print('  Folder paths: $folderPaths');
          print('  Song counts: $songCounts');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving folders to cache: $e');
      }
      rethrow;
    }
  }

  /// Recursively finds audio files in a directory
  Future<List<File>> _findAudioFiles(Directory directory) async {
    final List<File> audioFiles = [];
    int fileCount = 0;
    int audioFileCount = 0;

    if (kDebugMode) {
      print('Scanning directory: ${directory.path}');
    }

    try {
      await for (var entity in directory.list(recursive: true)) {
        try {
          fileCount++;
          if (fileCount % 100 == 0 && kDebugMode) {
            print(
              'Scanned $fileCount files, found $audioFileCount audio files so far...',
            );
          }

          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') ||
                path.endsWith('.wav') ||
                path.endsWith('.m4a') ||
                path.endsWith('.aac') ||
                path.endsWith('.flac') ||
                path.endsWith('.ogg')) {
              audioFiles.add(entity);
              audioFileCount++;

              if (kDebugMode && audioFileCount <= 5) {
                print('Found audio file: ${entity.path}');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing file ${entity.path}: $e');
          }
          continue;
        }
      }

      if (kDebugMode) {
        print(
          'Scan complete. Scanned $fileCount files, found $audioFileCount audio files.',
        );
        if (audioFileCount == 0) {
          print(
            'No audio files found. Make sure you have music files in the selected directory.',
          );
          print('Supported formats: .mp3, .wav, .m4a, .aac, .flac, .ogg');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning directory ${directory.path}: $e');
        if (e is Error) {
          print('Stack trace: ${e.stackTrace}');
        }
      }
      rethrow;
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
          final folders = await findAudioFolders(Directory(directoryPath));
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
              final folders = await findAudioFolders(directory);
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
  Future<List<AudioFolder>> findAudioFolders(Directory directory) async {
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
            folderSongCount[parentPath] =
                (folderSongCount[parentPath] ?? 0) + 1;
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

  /// Scans for audio folders with optional force rescan
  Future<List<AudioFolder>> scanAudioFolders({bool forceRescan = false}) async {
    try {
      if (!forceRescan) {
        // Try auto-scanning common folders first
        final autoFolders = await autoScanForAudioFolders();
        if (autoFolders.isNotEmpty) {
          if (kDebugMode) {
            print('Found ${autoFolders.length} folders in auto-scan');
          }
          await _saveFoldersToCache(autoFolders);
          return autoFolders;
        }

        // Try to get cached folders if auto-scan didn't find anything
        final cachedFolders = await getCachedFolders();
        if (cachedFolders.isNotEmpty) {
          if (kDebugMode) {
            print('Found ${cachedFolders.length} folders in cache');
          }
          return cachedFolders;
        }
      }

      // Fall back to full scan if auto-scan finds nothing or forceRescan is true
      final folders = await scanForAudioFolders();
      if (kDebugMode) {
        print('Scanned ${folders.length} folders');
      }
      // Cache the first folder path if found
      if (folders.isNotEmpty) {
        await _saveFoldersToCache(folders);
      }
      return folders;
    } catch (e) {
      if (kDebugMode) {
        print('Error in scanAudioFolders: $e');
      }
      rethrow;
    }
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
