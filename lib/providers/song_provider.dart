import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'audio_provider.dart';

class SongProvider with ChangeNotifier {
  List<Song> _songs = [];
  List<Song> _recentlyPlayed = [];
  bool _isLoading = false;
  String? _error;
  // AudioProvider will be injected through constructor
  final AudioProvider _audioProvider;

  SongProvider({required AudioProvider audioProvider})
    : _audioProvider = audioProvider;

  List<Song> get songs => List.unmodifiable(_songs);
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSongs() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get songs from the playlist in AudioProvider
      _songs = List<Song>.from(_audioProvider.playlist);
      _error = null;

      _recentlyPlayed = [];
    } catch (e) {
      _error = 'Failed to load songs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sortSongs(int Function(Song, Song) compare) {
    // Create a new list before sorting
    final newSongs = List<Song>.from(_songs);
    newSongs.sort(compare);
    _songs = newSongs;
    notifyListeners();
  }

  List<Song> searchSongs(String query) {
    if (query.isEmpty) return [];
    final queryLower = query.toLowerCase();
    return _songs.where((song) {
      return song.title.toLowerCase().contains(queryLower) ||
          song.artist.toLowerCase().contains(queryLower) ||
          song.album.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Clears the cache and refreshes the song list
  /// Returns true if the cache was cleared successfully, false otherwise
  Future<bool> clearCacheAndRefresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear the playlist in AudioProvider
      _audioProvider.setPlaylist([]);
      // Reload songs (which will be empty now)
      await loadSongs();
      return true;
    } catch (e) {
      _error = 'Failed to clear cache: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a method to get a song by its path
  Song? getSongByPath(String path) {
    try {
      return _songs.firstWhere((song) => song.path == path);
    } catch (e) {
      return null;
    }
  }

  // Add a song to recently played list
  void addToRecentlyPlayed(Song song) {
    // Remove the song if it already exists in the list
    _recentlyPlayed.removeWhere((s) => s.path == song.path);

    // Add to the beginning of the list
    _recentlyPlayed.insert(0, song);

    // Keep only the last 50 recently played songs
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 50);
    }

    notifyListeners();

    // Here you would typically save to shared preferences or local storage
    // _saveRecentlyPlayedToPrefs();
  }

  /// Adds songs from a list of PlatformFile objects
  /// Returns a list of newly added songs
  Future<List<Song>> addSongsFromFiles(List<PlatformFile> files) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSongs = <Song>[];

      // Filter out invalid files and process valid ones
      for (final file in files) {
        if (file.path == null) continue;

        final filePath = file.path!;
        final fileExists = await File(filePath).exists();

        if (fileExists) {
          // Check if song already exists
          final existingSong = getSongByPath(filePath);
          if (existingSong == null) {
            // Create new song from file
            final song = Song(
              title: _getFileNameWithoutExtension(file.name),
              artist: 'Unknown Artist',
              path: filePath,
              duration: const Duration(), // Will be updated by audio service
              album: 'Unknown Album',
              // Add other metadata from the file if available
            );
            newSongs.add(song);
          }
        }
      }

      if (newSongs.isNotEmpty) {
        _songs.addAll(newSongs);
        // Optionally save the updated list to persistent storage here
        // await _saveSongs();
      }

      _error = null;
      return newSongs;
    } catch (e) {
      _error = 'Failed to add songs: $e';
      if (kDebugMode) {
        print('Error in addSongsFromFiles: $e');
      }
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get file name without extension
  String _getFileNameWithoutExtension(String fileName) {
    return path.basenameWithoutExtension(fileName);
  }
}
