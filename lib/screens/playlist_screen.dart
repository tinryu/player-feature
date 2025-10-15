import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:playermusic1/widgets/player_min.dart';
import 'dart:async';
import '../services/audio_service.dart';
import '../services/audio_scanner_service.dart';
import '../models/song.dart';
import '../models/audio_folder.dart';
import '../widgets/song_list_widget.dart';
import '../widgets/folder_list_widget.dart';
import '../utils/helper.dart';
import '../utils/permission_helper.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with TickerProviderStateMixin {
  late final AudioService _audioService;
  final AudioScannerService _audioScanner = AudioScannerService();
  late TabController _tabController;
  List<Song> _songs = [];
  // ignore: unused_field
  Song? _currentSong;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _playerBarAnimationController;
  late Animation<double> _playerBarAnimation;
  bool _isPlayerBarVisible = false;
  List<AudioFolder> _audioFolders = [];
  bool _isLoadingFolders = false;

  @override
  void dispose() {
    _animationController.dispose();
    _playerBarAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize equalizer icon animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize player bar fade animation
    _playerBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _playerBarAnimation = CurvedAnimation(
      parent: _playerBarAnimationController,
      curve: Curves.easeInOut,
    );

    // Request permissions first, then load songs
    _requestPermissionsAndLoad();

    // Listen for song changes
    _audioService.currentSongStream.listen((song) {
      if (mounted) {
        setState(() {
          _currentSong = song;
          // Show player bar when a song is selected
          if (song != null && !_isPlayerBarVisible) {
            _isPlayerBarVisible = true;
            _playerBarAnimationController.forward();
          }
        });
      }
    });
  }

  Future<void> _showClearCacheDialog() async {
    final shouldClear = await Helper.showConfirmationDialog(
      context: context,
      title: 'Clear Cache',
      content: 'This will remove all cached music data. Are you sure?',
      cancelText: 'CANCEL',
      confirmText: 'CLEAR',
    );

    if (shouldClear == true) {
      try {
        await _audioService.clearCache();
        if (mounted) {
          setState(() {
            _songs = [];
            _currentSong = null;
            // Hide player bar when cache is cleared
            if (_isPlayerBarVisible) {
              _playerBarAnimationController.reverse();
              _isPlayerBarVisible = false;
            }
          });
          Helper.showSnackBar(context, 'Cache cleared successfully');
        }
      } catch (e) {
        if (mounted) {
          Helper.showSnackBar(context, 'Failed to clear cache: $e');
        }
      }
    }
  }

  Future<void> _requestPermissionsAndLoad() async {
    // Request storage permission on app start
    final hasPermission = await PermissionHelper.requestStoragePermission(context);
    if (hasPermission) {
      // Load existing songs
      await _loadSongs();
      // Auto scan for folders
      await _autoScanFolders();
    } else {
      if (mounted) {
        Helper.showSnackBar(
          context,
          'Storage permission is required to access music files',
        );
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      // First load any cached songs
      await _audioService.loadCachedPlaylist();

      // Then update the UI with the loaded songs
      if (mounted) {
        setState(() {
          _songs = _audioService.getSongs();
        });
      }

      // Optionally scan for new audio files (uncomment if needed)
      // await _scanForAudioFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading songs: $e')));
      }
    }
  }

  Future<void> _scanForAudioFiles() async {
    // Check permission before scanning
    final hasPermission = await PermissionHelper.requestStoragePermission(context);
    if (!hasPermission) {
      return;
    }

    try {
      final files = await _audioScanner.scanForAudioFiles();
      if (files.isNotEmpty) {
        _audioService.addSongs(files);
        if (mounted) {
          setState(() {
            _songs = _audioService.getSongs();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning for audio files: $e')),
        );
      }
    }
  }

  Future<void> _pickAndAddFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        _audioService.addSongs(files);
        if (mounted) {
          setState(() {
            _songs = _audioService.getSongs();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${files.length} song(s) to playlist'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
      }
    }
  }

  Future<void> _autoScanFolders() async {
    setState(() {
      _isLoadingFolders = true;
    });

    try {
      // Check permission before scanning
      final hasPermission = await PermissionHelper.hasStoragePermission();
      if (!hasPermission) {
        setState(() {
          _isLoadingFolders = false;
        });
        return;
      }

      final folders = await _audioScanner.autoScanForAudioFolders();
      if (mounted) {
        setState(() {
          _audioFolders = folders;
          _isLoadingFolders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
      }
    }
  }

  Future<void> _scanForFolders() async {
    // Check permission before scanning
    final hasPermission = await PermissionHelper.requestStoragePermission(context);
    if (!hasPermission) {
      return;
    }

    setState(() {
      _isLoadingFolders = true;
    });

    try {
      final folders = await _audioScanner.scanForAudioFolders();
      if (mounted) {
        setState(() {
          _audioFolders = folders;
          _isLoadingFolders = false;
        });
        if (folders.isNotEmpty) {
          Helper.showSnackBar(
            context,
            'Found ${folders.length} folder${folders.length > 1 ? 's' : ''} with audio files',
          );
        } else {
          Helper.showSnackBar(context, 'No folders with audio files found');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
        Helper.showSnackBar(context, 'Error scanning folders: $e');
      }
    }
  }

  Future<void> _onFolderTap(AudioFolder folder) async {
    try {
      final files = await _audioScanner.getAudioFilesFromFolder(folder.path);
      if (files.isNotEmpty) {
        _audioService.addSongs(files);
        if (mounted) {
          setState(() {
            _songs = _audioService.getSongs();
          });
          Helper.showSnackBar(
            context,
            'Added ${files.length} song${files.length > 1 ? 's' : ''} from ${folder.name}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helper.showSnackBar(context, 'Error loading folder: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
        toolbarHeight: 50,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Cache',
            onPressed: _showClearCacheDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Music Player v1.0.0',
            onPressed: () => {},
          ),
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: TabBar(
                  tabAlignment: TabAlignment.fill,
                  controller: _tabController,
                  labelColor: Colors.black,
                  labelPadding: EdgeInsets.zero,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.black,
                  indicatorPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(text: 'Playlist'),
                    Tab(text: 'Tracks'),
                    Tab(text: 'Recent'),
                    Tab(text: 'Folder'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Playlist Tab
                    _songs.isEmpty
                        ? const Center(child: Text('No songs in playlist'))
                        : SongListWidget(
                            songs: _songs,
                            audioService: _audioService,
                            fadeAnimation: _fadeAnimation,
                          ),
                    // Tracks Tab
                    _songs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No tracks found'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _scanForAudioFiles,
                                  child: const Text('Scan for Audio Files'),
                                ),
                              ],
                            ),
                          )
                        : SongListWidget(
                            songs: _songs,
                            audioService: _audioService,
                            fadeAnimation: _fadeAnimation,
                          ),
                    // Recently Played Tab
                    _songs.isEmpty
                        ? const Center(child: Text('No recently played tracks'))
                        : SongListWidget(
                            songs: _audioService.getRecentlyPlayed(),
                            audioService: _audioService,
                            fadeAnimation: _fadeAnimation,
                          ),
                    // Folder Tab
                    _isLoadingFolders
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Scanning for audio folders...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _audioFolders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_off_rounded,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No audio folders found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adding music to Music or Downloads folder',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _scanForFolders,
                                  icon: const Icon(Icons.folder_open_rounded),
                                  label: const Text('Browse Folders'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_audioFolders.length} folder${_audioFolders.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _scanForFolders,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Rescan'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: FolderListWidget(
                                  folders: _audioFolders,
                                  onFolderTap: _onFolderTap,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
          if (_isPlayerBarVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _playerBarAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(_playerBarAnimation),
                  child: Material(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: StreamBuilder<Duration>(
                        stream: _audioService.positionStream,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: _audioService.durationStream,
                            builder: (context, durationSnapshot) {
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              return PlayerMinBar(
                                isPlaying: _audioService.isPlaying,
                                position: position,
                                duration: duration,
                                onPlayPause: _audioService.togglePlayPause,
                                onNext: _audioService.next,
                                onPrevious: _audioService.previous,
                                onShuffle: _audioService.shuffle,
                                onRepeat: _audioService.repeat,
                                onOpenFiles: _pickAndAddFiles,
                                songTitle:
                                    _currentSong?.title ?? 'No song selected',
                                currentSong: _currentSong,
                                audioService: _audioService,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_rounded),
            label: 'My Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_rounded),
            label: 'Online',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}
