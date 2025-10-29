// ignore_for_file: unused_field

import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/equalizer_service.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isRepeatEnabled = false;
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();

  // Equalizer service integration
  EqualizerService? _equalizerService;

  // Sleep timer
  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;
  final StreamController<int> _sleepTimerController =
      StreamController<int>.broadcast();

  // Stream controllers for state management
  final StreamController<List<Song>> _playlistController =
      StreamController<List<Song>>.broadcast();
  final StreamController<int> _currentIndexController =
      StreamController<int>.broadcast();
  final StreamController<Song?> _currentSongController =
      StreamController<Song?>.broadcast();

  // Getters for streams
  Stream<List<Song>> get playlistStream => _playlistController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  // Position and duration streams
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // Get current song
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // Play a specific song
  Future<void> play(Song song) async {
    try {
      _currentIndex = _playlist.indexWhere((s) => s.path == song.path);
      if (_currentIndex != -1) {
        await _audioPlayer.play(DeviceFileSource(song.path));
        _currentSongController.add(song);
        _currentIndexController.add(_currentIndex);
        await _savePlaylistToCache();
      }
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  // Toggle repeat mode
  void repeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
  }

  // Check if repeat is enabled
  bool get isRepeatEnabled => _isRepeatEnabled;

  // Seek to a specific position in the current track
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  static const String _cachedPlaylistKey = 'cached_playlist';
  static const String _currentIndexKey = 'current_playlist_index';

  // Getter for current playing state
  bool get isPlaying => _isPlaying;

  // Stream for playing state changes
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  AudioService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _updatePlayingState(state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRepeatEnabled && _currentIndex != -1) {
        play(_playlist[_currentIndex]);
      } else {
        next();
      }
    });

    // Load cached playlist when service initializes
    loadCachedPlaylist();
  }

  // Set equalizer service reference
  void setEqualizerService(EqualizerService equalizerService) {
    _equalizerService = equalizerService;
    _equalizerService?.setAudioPlayer(_audioPlayer);
  }

  // Save playlist to cache
  Future<void> _savePlaylistToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = jsonEncode(
        _playlist.map((song) => song.toJson()).toList(),
      );
      await prefs.setString(_cachedPlaylistKey, playlistJson);
      await prefs.setInt(_currentIndexKey, _currentIndex);
    } catch (e) {
      print('Error saving playlist to cache: $e');
    }
  }

  // Load playlist from cache
  Future<void> loadCachedPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = prefs.getString(_cachedPlaylistKey);

      if (playlistJson != null && playlistJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(playlistJson);
        final List<Song> cachedSongs = jsonList
            .map((json) => Song.fromJson(json))
            .toList();

        if (cachedSongs.isNotEmpty) {
          _playlist.clear();
          _playlist.addAll(cachedSongs);
          _playlistController.add(List.from(_playlist));

          // Load the last played index if available
          final lastIndex = prefs.getInt(_currentIndexKey) ?? -1;
          if (lastIndex >= 0 && lastIndex < _playlist.length) {
            _setCurrentIndex(lastIndex, notify: false);
          }
        }
      }
    } catch (e) {
      print('Error loading cached playlist: $e');
    }
  }

  Future<bool> clearCache() async {
    try {
      // Clear data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_cachedPlaylistKey),
        prefs.remove(_currentIndexKey),
      ]);

      // Reset internal state
      _playlist.clear();
      _currentIndex = -1;
      _isPlaying = false;

      // Stop any ongoing playback
      await _audioPlayer.stop();

      // Update all controllers with the cleared state
      _playlistController.add([]); // Use empty list directly
      _currentSongController.add(null);
      _currentIndexController.add(-1);
      _isPlaying = false;
      _isPlayingController.add(false);

      // Notify all listeners after updating controllers
      notifyListeners();

      return true; // Success
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false; // Failure
    }
  }

  // Add songs to playlist
  void addToPlaylist(List<Song> songs) {
    _playlist.addAll(songs);
    _playlistController.add(List.from(_playlist));
    if (_currentIndex == -1 && _playlist.isNotEmpty) {
      _setCurrentIndex(0);
    }
    _savePlaylistToCache();
  }

  // Add files as songs to the playlist
  void addSongs(List<File> files) {
    final newSongs = files
        .map(
          (file) => Song(
            title: file.path.split('/').last,
            artist: 'Unknown Artist',
            path: file.path,
            album: 'Unknown Album',
            duration: const Duration(seconds: 0),
          ),
        )
        .toList();

    addToPlaylist(newSongs);
  }

  // Ensure the playlist is loaded from cache
  Future<void> ensurePlaylistLoaded() async {
    if (_playlist.isEmpty) {
      await loadCachedPlaylist();
    }
  }

  // Get all songs in the playlist
  Future<List<Song>> getSongs() async {
    await ensurePlaylistLoaded();
    print('Getting songs. Playlist length: ${_playlist.length}');
    return List.from(_playlist);
  }

  // Play a specific song from the playlist
  Future<void> playSong(Song song) async {
    final index = _playlist.indexWhere((s) => s.path == song.path);
    if (index != -1) {
      // Update lastPlayed timestamp
      _playlist[index] = _playlist[index].copyWith(lastPlayed: DateTime.now());
      _setCurrentIndex(index);
      await _playCurrentSong();
      _playlistController.add(List.from(_playlist));
      _isPlaying = true;
      _isPlayingController.add(_isPlaying);
    }
  }

  // Shuffle the playlist
  void shuffle() {
    if (_playlist.isEmpty) return;

    // Store the current song and its state
    final currentSong = _currentIndex != -1 ? _playlist[_currentIndex] : null;
    final wasPlaying = _isPlaying;

    // Create a new shuffled list
    final shuffledList = List<Song>.from(_playlist)..shuffle();

    // Find the current song in the shuffled list
    int newIndex = -1;
    if (currentSong != null) {
      newIndex = shuffledList.indexWhere((s) => s.path == currentSong.path);
      if (newIndex == -1) {
        // If current song not found in shuffled list (shouldn't happen), use first song
        newIndex = 0;
      }
    } else if (shuffledList.isNotEmpty) {
      newIndex = 0;
    }

    // Update the playlist and current index
    _playlist.clear();
    _playlist.addAll(shuffledList);
    _currentIndex = newIndex;

    // If a song was playing, continue playing from the new position
    if (wasPlaying && _currentIndex != -1) {
      playSong(_playlist[_currentIndex]);
    }

    // Notify listeners
    _playlistController.add(List<Song>.from(_playlist));
    _currentIndexController.add(_currentIndex);
    _currentSongController.add(
      _currentIndex != -1 ? _playlist[_currentIndex] : null,
    );

    // Save the updated playlist
    _savePlaylistToCache();

    // Notify any listeners of the change
    notifyListeners();
  }

  // Get recently played songs (most recent first)
  List<Song> getRecentlyPlayed({int limit = 10}) {
    final sortedSongs = List<Song>.from(_playlist)
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return sortedSongs.take(limit).toList();
  }

  // Play the current song
  Future<void> _playCurrentSong() async {
    if (_currentIndex == -1 || _playlist.isEmpty) return;

    final song = _playlist[_currentIndex];
    // Update last played timestamp
    _playlist[_currentIndex] = song.copyWith(lastPlayed: DateTime.now());
    await _audioPlayer.setSource(DeviceFileSource(song.path));
    await _audioPlayer.resume();
    _currentSongController.add(song);
  }

  // Play next song
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    int nextIndex = (_currentIndex + 1) % _playlist.length;
    _setCurrentIndex(nextIndex);
    await _playCurrentSong();
  }

  // Play previous song
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    int prevIndex = (_currentIndex - 1) >= 0
        ? _currentIndex - 1
        : _playlist.length - 1;
    _setCurrentIndex(prevIndex);
    await _playCurrentSong();
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pausePlayback();
    } else if (_currentIndex != -1) {
      await _playCurrentSong();
    } else if (_playlist.isNotEmpty) {
      _setCurrentIndex(0);
      await _playCurrentSong();
    }
  }

  // Play previous song
  Future<void> prev() async {
    if (_playlist.isEmpty) return;

    int prevIndex = (_currentIndex - 1) >= 0
        ? _currentIndex - 1
        : _playlist.length - 1;
    _setCurrentIndex(prevIndex);
    await _playCurrentSong();
  }

  // Update playing state and notify listeners
  void _updatePlayingState(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      _isPlayingController.add(playing);
    }
  }

  // Pause the current playback
  Future<void> pausePlayback() async {
    await _audioPlayer.pause();
    _updatePlayingState(false);
  }

  // Alias for pausePlayback for backward compatibility
  Future<void> pause() => pausePlayback();

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _updatePlayingState(false);
  }

  // Update current index and notify listeners
  void _setCurrentIndex(int index, {bool notify = true}) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      if (notify) {
        _currentIndexController.add(_currentIndex);
        _currentSongController.add(currentSong);
        _savePlaylistToCache(); // Save when current index changes
      }
    }
  }

  // Sleep timer functionality
  Stream<int> get sleepTimerStream => _sleepTimerController.stream;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  void setSleepTimer(int minutes) {
    // Cancel existing timer
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepTimerController.add(minutes);

    if (minutes > 0) {
      // Set new timer
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        pausePlayback();
        _sleepTimerMinutes = 0;
        _sleepTimerController.add(0);
      });
    }
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = 0;
    _sleepTimerController.add(0);
  }

  // Position and duration tracking
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  @override
  void dispose() {
    // Stop any ongoing playback
    _audioPlayer.stop();

    // Close all stream controllers
    _isPlayingController.close();
    _playlistController.close();
    _currentIndexController.close();
    _currentSongController.close();
    _sleepTimerController.close();

    // Cancel any active timers
    _sleepTimer?.cancel();

    // Dispose of audio player and equalizer
    _audioPlayer.dispose();
    _equalizerService?.dispose();

    // Call super dispose last
    super.dispose();
  }
}
