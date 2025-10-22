import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/equalizer_service.dart';

class AudioService {
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

  // Clear the cache and reset playlist
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedPlaylistKey);
      await prefs.remove(_currentIndexKey);

      _playlist.clear();
      _currentIndex = -1;
      _playlistController.add(List.from(_playlist));
      _currentSongController.add(null);
      _currentIndexController.add(-1);

      await _audioPlayer.stop();
      _updatePlayingState(false);
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
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

    final currentSong = _currentIndex != -1 ? _playlist[_currentIndex] : null;
    _playlist.shuffle();
    _playlistController.add(List.from(_playlist));

    if (currentSong != null) {
      final newIndex = _playlist.indexWhere((s) => s.path == currentSong.path);
      if (newIndex != -1) {
        _setCurrentIndex(newIndex);
      }
    }
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

  void dispose() {
    _sleepTimer?.cancel();
    _isPlayingController.close();
    _playlistController.close();
    _currentIndexController.close();
    _currentSongController.close();
    _sleepTimerController.close();
    _audioPlayer.dispose();
  }
}
