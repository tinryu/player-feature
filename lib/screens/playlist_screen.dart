// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/player_min.dart';
import '../services/audio_scanner_service.dart';
import '../services/equalizer_service.dart';
import '../models/song.dart';
import '../models/audio_folder.dart';
import '../widgets/song_list_widget.dart';
import '../widgets/folder_list_widget.dart';
import '../utils/helper.dart';
import '../utils/permission_helper.dart';
import '../providers/song_provider.dart';
import '../providers/audio_provider.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  PlaylistScreenState createState() => PlaylistScreenState();
}

/// Extension to access the PlaylistScreenState from the context
extension PlaylistScreenStateExtension on BuildContext {
  PlaylistScreenState? get playlistScreenState =>
      findAncestorStateOfType<PlaylistScreenState>();
}

class PlaylistScreenState extends State<PlaylistScreen>
    with TickerProviderStateMixin {
  late final AudioProvider _audioProvider;
  late final EqualizerService _equalizerService;

  final AudioScannerService _audioScanner = AudioScannerService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _playerBarAnimationController;
  late Animation<double> _playerBarAnimation;
  Song? _currentSong;
  bool _sortAscending = true; // true for A-Z, false for Z-A
  bool _isPlayerBarVisible = false;
  bool _isLoadingFolders = false;
  bool get isPlayerBarVisible => _isPlayerBarVisible;
  List<Song> _getSongs(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.watch<SongProvider>().songs;
    } else {
      return context.read<SongProvider>().songs;
    }
  }

  List<Song> _getRecentlyPlayed(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.watch<SongProvider>().recentlyPlayed;
    } else {
      return context.read<SongProvider>().recentlyPlayed;
    }
  }

  List<AudioFolder> _audioFolders = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Song> _filteredSongs = [];

  void showPlayerBar() {
    if (!mounted) return;

    // Ensure the player bar is visible
    _isPlayerBarVisible = true;

    // Reset and start the animation
    if (_playerBarAnimationController.isCompleted) {
      _playerBarAnimationController.reset();
    }

    if (!_playerBarAnimationController.isAnimating) {
      _playerBarAnimationController.forward();
    }

    // Force a rebuild
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize services
    _audioProvider = context.read<AudioProvider>();
    _audioProvider.addListener(_onAudioChange);
    _equalizerService = EqualizerService();
    _tabController = TabController(length: 3, vsync: this);
    // Set up animations
    _initAnimations();
    _initAudioService();
    _initData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _playerBarAnimationController.dispose();
    _tabController.dispose();
    _audioProvider.removeListener(_onAudioChange);
    super.dispose();
  }

  Future _initData() async {
    final songProvider = context.read<SongProvider>();
    final files = await _audioScanner.getCachedFiles();
    final folders = await _audioScanner.getCachedFolders();
    //Load cached file all directory
    if (files != null) {
      _audioProvider.setPlaylist(
        files.map((file) => Song.fromFile(file.path)).toList(),
      );
      songProvider.loadSongs();
    }

    if (folders.isNotEmpty) {
      if (mounted) {
        setState(() {
          _audioFolders = folders;
        });
      }
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
    _fadeController.forward();

    _playerBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _playerBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _playerBarAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initAudioService() async {
    try {
      // Request storage permission
      final hasPermission = await PermissionHelper.requestStoragePermission(
        context,
      );

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to access music files',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Initialize audio service and load songs
      final songProvider = context.read<SongProvider>();

      if (songProvider.songs.isEmpty) {
        await songProvider.loadSongs();
      }
      // Start fade in animation
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing audio service: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onAudioChange() {
    if (!mounted) return;
    
    final newSong = _audioProvider.currentSong;
    
    // Only call setState if the current song actually changed
    // Don't rebuild for play/pause state changes
    if (_currentSong?.path != newSong?.path) {
      setState(() {
        _currentSong = newSong;
        if (_currentSong != null && !_isPlayerBarVisible) {
          _isPlayerBarVisible = true;
          _playerBarAnimationController.forward();
        }
      });
    } else if (newSong != null && !_isPlayerBarVisible) {
      // Only update player bar visibility without full rebuild
      setState(() {
        _isPlayerBarVisible = true;
      });
      _playerBarAnimationController.forward();
    }
  }

  void _filterSongs(String query, BuildContext context) async {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredSongs = [];
      });
      return;
    }

    // Debounce the search to avoid too many rebuilds
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final songProvider = context.read<SongProvider>();
    final filtered = songProvider.songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              (song.artist.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();

    if (mounted) {
      setState(() {
        _filteredSongs = filtered;
      });
    }
  }

  Future<void> _showClearCacheDialog() async {
    final shouldClear = await Helper.showConfirmationDialog(
      context: context,
      title: 'Clear Cache',
      content:
          'This will remove all cached data and reset the player. Continue?',
      confirmText: 'Clear',
    );

    if (shouldClear == true && mounted) {
      try {
        final songProvider = context.read<SongProvider>();
        final success = await songProvider.clearCacheAndRefresh();

        if (mounted) {
          // Clear current song and hide player bar
          setState(() {
            _currentSong = null;
            _isPlayerBarVisible = false;
          });

          // Force a rebuild of the widget tree
          if (success) {
            await songProvider.loadSongs(); // Ensure songs are reloaded
            setState(() {}); // Trigger a rebuild
            Helper.showSnackBar(context, 'Cache cleared successfully');
          } else {
            Helper.showSnackBar(context, 'Failed to clear cache');
          }
        }
      } catch (e) {
        if (mounted) {
          Helper.showSnackBar(context, 'Error clearing cache: $e');
        }
      }
    }
  }

  Future<void> _scanForFolders({bool forceRescan = false}) async {
    final hasPermission = await PermissionHelper.requestStoragePermission(
      context,
    );
    if (!hasPermission) {
      return;
    }

    setState(() {
      _isLoadingFolders = true;
    });

    try {
      final folders = await _audioScanner.scanAudioFolders(
        forceRescan: forceRescan,
      );
      setState(() => _audioFolders = folders);
    } catch (e) {
      if (mounted) {
        Helper.showSnackBar(context, 'Error scanning folders: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
      }
    }
  }

  Future<void> _onFolderTap(AudioFolder folder) async {
    try {
      final files = await _audioScanner.getAudioFilesFromFolder(folder.path);
      if (files.isNotEmpty) {
        final songs = files.map((file) => Song.fromFile(file.path)).toList();
        _audioProvider.addSongs(songs);
        if (mounted) {
          final songProvider = context.read<SongProvider>();
          await songProvider.loadSongs();
          if (mounted) {
            if (_tabController.length > 1) {
              _tabController.animateTo(
                1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
              );
              // _playSong(songs.first);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Helper.showSnackBar(context, 'Error loading folder: $e');
      }
    }
  }

  Future<void> _playSong(Song song) async {
    await _audioProvider.playSong(song);
    setState(() {
      _currentSong = song;
      _isPlayerBarVisible = true;
    });

    final songProvider = context.read<SongProvider>();
    songProvider.addToRecentlyPlayed(song);
  }

  Future<void> _openFolderPicker() async {
    final result = await _audioScanner.clearCachedFolders();
    if (result) {
      await _scanForFolders(forceRescan: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared and folders refreshed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear cache'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _getSongs(context);
    final recentlyPlayed = _getRecentlyPlayed(context);
    return Scaffold(
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
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  labelPadding: EdgeInsets.zero,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Theme.of(context).colorScheme.onSurface,
                  indicatorPadding: EdgeInsets.zero,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,

                  dividerColor: Colors.grey.withValues(alpha: 0.2),
                  tabs: const [
                    Tab(icon: Icon(Icons.folder_rounded)),
                    Tab(icon: Icon(Icons.queue_music_rounded)),
                    Tab(icon: Icon(Icons.recent_actors_rounded)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
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
                                TextButton(
                                  onPressed: () {
                                    _openFolderPicker();
                                  },
                                  child: const Text('Open Folders'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      PopupMenuButton<String>(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        menuPadding: EdgeInsets.all(5),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'open_folder',
                                            height:
                                                40, // Fixed height for consistent item size
                                            onTap: _openFolderPicker,
                                            child: SizedBox(
                                              width: double
                                                  .infinity, // Make the item take full width
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .create_new_folder_sharp,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(
                                                    width: 12,
                                                  ), // Space between icon and text
                                                  Text(
                                                    'Open folder',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          PopupMenuDivider(
                                            thickness: 0.3,
                                            height: 0.5,
                                            color: Colors.grey,
                                          ), // Divider between items
                                          PopupMenuItem(
                                            value: 'sort',
                                            height:
                                                40, // Same height as other items
                                            child: SizedBox(
                                              width:
                                                  double.infinity, // Full width
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.swap_vert_rounded,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _sortAscending
                                                        ? 'Z → A'
                                                        : 'A → Z',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _sortAscending =
                                                    !_sortAscending;
                                                // Sort the folders list
                                                _audioFolders.sort((a, b) {
                                                  final nameA = a.name
                                                      .toLowerCase();
                                                  final nameB = b.name
                                                      .toLowerCase();
                                                  return _sortAscending
                                                      ? nameA.compareTo(nameB)
                                                      : nameB.compareTo(nameA);
                                                });
                                              });
                                            },
                                          ),
                                        ],
                                        icon: Icon(Icons.menu_rounded),
                                        iconSize: 24,
                                        position: PopupMenuPosition.under,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FolderListWidget(
                                  folders: _audioFolders,
                                  onFolderTap: _onFolderTap,
                                ),
                              ),
                              SizedBox(height: 70),
                            ],
                          ),
                    // PlayList Tab
                    songs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [const Text('No songs in playlist')],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (value) =>
                                              _filterSongs(value, context),
                                          decoration: InputDecoration(
                                            hintText: 'Search songs...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            suffixIcon: _isSearching
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _searchController
                                                            .clear();
                                                        _isSearching = false;
                                                        _filteredSongs = [];
                                                      });
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        menuPadding: EdgeInsets.all(5),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'playlist_count',
                                            height:
                                                40, // Fixed height for consistent item size
                                            child: Text(
                                              '${songs.length} songs',
                                            ),
                                          ),
                                          PopupMenuDivider(),
                                          PopupMenuItem(
                                            value: 'clear_cache',
                                            height:
                                                40, // Fixed height for consistent item size
                                            onTap: _showClearCacheDialog,
                                            child: SizedBox(
                                              width: double
                                                  .infinity, // Make the item take full width
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.delete_sweep_rounded,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(
                                                    width: 12,
                                                  ), // Space between icon and text
                                                  Text(
                                                    'Remove lists',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          PopupMenuDivider(
                                            thickness: 0.3,
                                            height: 0.5,
                                            color: Colors.grey,
                                          ), // Divider between items
                                          PopupMenuItem(
                                            value: 'sort',
                                            height:
                                                40, // Same height as other items
                                            child: SizedBox(
                                              width:
                                                  double.infinity, // Full width
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.swap_vert_rounded,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(
                                                    width: 12,
                                                  ), // Space between icon and text
                                                  Text(
                                                    _sortAscending
                                                        ? 'Z → A'
                                                        : 'A → Z',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onTap: () {
                                              final songProvider = context
                                                  .read<SongProvider>();
                                              songProvider.sortSongs((a, b) {
                                                // First compare by title
                                                int comparison = a.title
                                                    .toLowerCase()
                                                    .compareTo(
                                                      b.title.toLowerCase(),
                                                    );

                                                // If titles are the same, compare by artist
                                                if (comparison == 0) {
                                                  comparison = a.artist
                                                      .toLowerCase()
                                                      .compareTo(
                                                        b.artist.toLowerCase(),
                                                      );

                                                  // If artists are also the same, compare by path as final tiebreaker
                                                  if (comparison == 0) {
                                                    comparison = a.path
                                                        .toLowerCase()
                                                        .compareTo(
                                                          b.path.toLowerCase(),
                                                        );
                                                  }
                                                }

                                                return _sortAscending
                                                    ? -comparison
                                                    : comparison;
                                              });
                                              setState(() {
                                                _sortAscending =
                                                    !_sortAscending;
                                              });
                                            },
                                          ),
                                        ],
                                        icon: Icon(Icons.menu_rounded),
                                        iconSize: 24,
                                        position: PopupMenuPosition.under,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _isSearching
                                    ? _filteredSongs.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No matching songs found',
                                              ),
                                            )
                                          : SongListWidget(
                                              key: const ValueKey(
                                                'filtered_songs',
                                              ),
                                              songs: _filteredSongs,
                                              onSongSelected: _playSong,
                                              fadeAnimation: _fadeAnimation,
                                              currentSong: _currentSong,
                                            )
                                    : Consumer<SongProvider>(
                                        builder: (context, songProvider, _) {
                                          return SongListWidget(
                                            key: ValueKey(
                                              'songs_${songProvider.songs.length}',
                                            ),
                                            songs: songProvider.songs,
                                            onSongSelected: _playSong,
                                            fadeAnimation: _fadeAnimation,
                                            currentSong: _currentSong,
                                          );
                                        },
                                      ),
                              ),
                              SizedBox(height: 70),
                            ],
                          ),
                    // Recently Played Tab
                    recentlyPlayed.isEmpty
                        ? Center(child: Text('No recently played tracks'))
                        : SongListWidget(
                            songs: recentlyPlayed,
                            onSongSelected: _playSong,
                            fadeAnimation: _fadeAnimation,
                            currentSong: _currentSong,
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
                        stream: _audioProvider.positionStream,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: _audioProvider.durationStream,
                            builder: (context, durationSnapshot) {
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              return PlayerMinBar(
                                position: position,
                                duration: duration,
                                // onOpenFiles: _pickAndAddFiles,
                                equalizerService: _equalizerService,
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
    );
  }
}
