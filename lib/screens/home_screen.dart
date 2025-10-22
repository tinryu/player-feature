import 'package:flutter/material.dart';
import '../models/song.dart';
import '../screens/playlist_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<PlaylistScreenState> _playlistScreenKey =
      GlobalKey<PlaylistScreenState>();

  late final AudioService _audioService;
  List<Song> _allSongs = [];

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    // Initialize services and load songs
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadSongs();
    });
  }

  Future<void> _loadSongs() async {
    try {
      print('Loading songs...');
      final songs = await _audioService.getSongs();
      print('Songs loaded: ${songs.length}');
      if (mounted) {
        setState(() {
          _allSongs = songs;
          print('_allSongs updated with ${_allSongs.length} songs');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load songs: $e')));
      }
    }
  }

  List<Widget> _buildPages() {
    print('_buildPages called. _allSongs length: ${_allSongs.length}');

    final searchPage = _allSongs.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SearchScreen(
            key: ValueKey('search_page_${_allSongs.length}'),
            allSongs: _allSongs,
            audioService: _audioService,
            onSongSelected: (song) async {
              // Switch to home tab (index 0) before playing song
              if (_selectedIndex != 0) {
                _onItemTapped(0);
              }
              // Wait for the tab switch to complete
              await Future.delayed(const Duration(milliseconds: 100));

              // Update the current song in PlaylistScreenState
              _playlistScreenKey.currentState?.setCurrentSong(song);

              // Show the player bar using the exposed method
              _playlistScreenKey.currentState?.showPlayerBar();
            },
          );

    return [
      PlaylistScreen(key: _playlistScreenKey),
      const Center(child: Text('Online Music')),
      searchPage,
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _buildPages(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                Set<WidgetState> states,
              ) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w600
                      : FontWeight.normal,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                Set<WidgetState> states,
              ) {
                return IconThemeData(
                  size: 24,
                  color: states.contains(WidgetState.selected)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 60,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
