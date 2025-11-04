// lib/providers/audio_provider.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 1.0;
  // Repeat modes: 0 = no repeat, 1 = repeat one, 2 = repeat all
  int _repeatMode = 0; // Store the volume before muting
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  List<Song> _playlist = [];
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  final StreamController<int> _sleepTimerController =
      StreamController<int>.broadcast();

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  int get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentSong;
  // List<Song> get playlist => _playlist;

  List<Song> get playList => List.unmodifiable(_playlist);

  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;
  Stream<int> get sleepTimerStream => _sleepTimerController.stream;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  /// Adds multiple songs to the playlist, avoiding duplicates
  /// Returns the number of new songs added
  int addSongs(List<Song> newSongs) {
    if (newSongs.isEmpty) return 0;
    // Filter out duplicates based on path
    final existingPaths = _playlist.map((s) => s.path).toSet();
    final uniqueNewSongs = newSongs
        .where((song) => !existingPaths.contains(song.path))
        .toList();

    if (uniqueNewSongs.isEmpty) return 0;

    _playlist.addAll(uniqueNewSongs);
    // If no song is currently playing, set the first song as current
    if (_currentSong == null && _playlist.isNotEmpty) {
      _currentSong = _playlist.first;
    }

    notifyListeners();
    return uniqueNewSongs.length;
  }

  /// Default constructor for production use
  AudioProvider() : _audioPlayer = AudioPlayer() {
    _init();
  }

  /// Test constructor that allows injecting a mock AudioPlayer
  @visibleForTesting
  AudioProvider.test({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _init();
  }

  void _init() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPlaying = state == PlayerState.playing;
        notifyListeners();
      });
    });

    void setDuration(Duration duration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _duration = duration;
        notifyListeners();
      });
    }

    _audioPlayer.onDurationChanged.listen((duration) {
      setDuration(duration);
    });

    void setPosition(Duration position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _position = position;
        notifyListeners();
      });
    }

    _audioPlayer.onPositionChanged.listen((position) {
      setPosition(position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();

        // Handle repeat functionality
        if (_repeatMode == 1) {
          // Repeat one: replay current song
          if (_currentSong != null) {
            playSong(_currentSong!);
          }
        } else if (_repeatMode == 2) {
          // Repeat all: play next or loop to first
          if (_playlist.isNotEmpty) {
            final currentIndex = _playlist.indexWhere((s) => s == _currentSong);
            if (currentIndex < _playlist.length - 1) {
              playSong(_playlist[currentIndex + 1]);
            } else if (currentIndex == _playlist.length - 1) {
              // If last song, loop back to first
              playSong(_playlist[0]);
            }
          }
        } else {
          // No repeat: just stop or play next if available
          if (_playlist.isNotEmpty) {
            final currentIndex = _playlist.indexWhere((s) => s == _currentSong);
            if (currentIndex < _playlist.length - 1) {
              playSong(_playlist[currentIndex + 1]);
            }
          }
        }
      });
    });
  }

  Future<void> playSong(Song song) async {
    try {
      // Check if file exists
      final file = File(song.path);
      final fileExists = await file.exists();
      if (!fileExists) {
        debugPrint('❌ Error: File does not exist at path: ${song.path}');
        return;
      }

      if (_currentSong?.path != song.path) {
        debugPrint('🔄 New song detected, stopping current playback');
        await _audioPlayer.stop();

        await setCurrentSong(song);
      } else if (!_isPlaying) {
        debugPrint('⏯️ Resuming playback...');
        await _audioPlayer.resume();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isPlaying = true;
          notifyListeners();
        });
        debugPrint('▶️ Playback resumed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error playing song: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPlaying = false;
        notifyListeners();
      });

      // Rethrow the error to be handled by the caller if needed
      rethrow;
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> setCurrentSong(Song song) async {
    _currentSong = song;
    await _audioPlayer.play(DeviceFileSource(song.path));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPlaying = true;
      notifyListeners();
    });
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> play() async {
    if (_currentSong == null) return;
    await _audioPlayer.play(DeviceFileSource(_currentSong!.path));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPlaying = true;
      notifyListeners();
    });
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _position = position;
      notifyListeners();
    });
  }

  Future<void> next() async {
    if (_playlist.isEmpty || _currentSong == null) return;

    final currentIndex = _playlist.indexWhere(
      (s) => s.path == _currentSong!.path,
    );
    if (currentIndex < _playlist.length - 1) {
      await playSong(_playlist[currentIndex + 1]);
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty || _currentSong == null) return;

    final currentIndex = _playlist.indexWhere(
      (s) => s.path == _currentSong!.path,
    );
    if (currentIndex > 0) {
      await playSong(_playlist[currentIndex - 1]);
    } else {
      // If at first song, restart it
      await seek(Duration.zero);
    }
  }

  void clearCurrentSong() {
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    notifyListeners();
  }

  void setPlaylist(List<Song> songs) {
    _playlist = List.from(songs);
    notifyListeners();
  }

  void shuffle() {
    if (_playlist.isEmpty) return;

    _playlist.shuffle();
    final currentIndex = _currentSong != null
        ? _playlist.indexWhere((s) => s.path == _currentSong!.path)
        : -1;

    if (currentIndex > 0) {
      // Move current song to the front
      final current = _playlist.removeAt(currentIndex);
      _playlist.insert(0, current);
    }

    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = (_repeatMode + 1) % 3; // Cycle through 0, 1, 2

    switch (_repeatMode) {
      case 0: // No repeat
        _audioPlayer.setReleaseMode(ReleaseMode.release);
        break;
      case 1: // Repeat one
        _audioPlayer.setReleaseMode(ReleaseMode.loop);
        break;
      case 2: // Repeat all
        _audioPlayer.setReleaseMode(ReleaseMode.release);
        break;
    }

    notifyListeners();
  }

  // Sleep timer methods
  void startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepTimerController.add(minutes);

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (_isPlaying) {
        stop();
      }
      _sleepTimer = null;
      _sleepTimerMinutes = 0;
      _sleepTimerController.add(0);
      notifyListeners();
    });

    notifyListeners();
  }

  void stopSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerMinutes = 0;
    _sleepTimerController.add(0);
    notifyListeners();
  }

  bool get isSleepTimerActive => _sleepTimer != null;
  int get remainingSleepMinutes {
    if (_sleepTimer == null) return 0;
    // Calculate remaining time in minutes, rounding up
    final remaining = _sleepTimer!.tick * _sleepTimer!.tick / 1000 / 60;
    return remaining.ceil();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      // Unmute: restore previous volume
      await _audioPlayer.setVolume(_volume);
    } else {
      // Mute: save current volume and set to 0
      _volume = _audioPlayer.volume;
      await _audioPlayer.setVolume(0);
    }
    _isMuted = !_isMuted;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    _sleepTimerController.close();
    super.dispose();
  }
}
