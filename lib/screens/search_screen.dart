import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:playermusic1/utils/helper.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../services/audio_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Song> _localSearchResults = [];
  Timer? _debounce;
  bool _isSearching = false;
  late TabController _tabController;
  bool _showOnlineResults = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Load songs if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final songProvider = context.read<SongProvider>();
      if (songProvider.songs.isEmpty) {
        songProvider.loadSongs();
      }
    });
  }

  void _handleTabSelection() {
    setState(() {
      _showOnlineResults = _tabController.index == 1;
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _performSearch(String query) {
    // Cancel any previous debounce timer
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _localSearchResults = [];
        _isSearching = false;
      });
      context.read<SongProvider>().clearOnlineSearch();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Set up debounce timer (500ms for online search)
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final songProvider = context.read<SongProvider>();

      // Always search local songs
      _localSearchResults = songProvider.searchSongs(query);

      // Search online if in online tab or if local results are empty
      // if (_tabController.index == 1 || _localSearchResults.isEmpty) {
      //   await songProvider.searchOnlineSongs(query);
      // }

      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to highlight matching text
  Text _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final matches = <String>[];

    int start = 0;
    int index;

    while ((index = textLower.indexOf(queryLower, start)) != -1) {
      if (index > start) {
        matches.add(text.substring(start, index));
      }
      matches.add(text.substring(index, index + queryLower.length));
      start = index + queryLower.length;
    }

    if (start < text.length) {
      matches.add(text.substring(start));
    }

    return Text.rich(
      TextSpan(
        children: matches.map((part) {
          final isMatch = part.toLowerCase() == queryLower;
          return TextSpan(
            text: part,
            style: TextStyle(
              color: isMatch ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isMatch ? FontWeight.bold : null,
              backgroundColor: isMatch
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
          );
        }).toList(),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, or albums...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                        _searchFocusNode.requestFocus();
                      },
                    )
                  : null,
              hintStyle: TextStyle(color: theme.hintColor),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            onChanged: _performSearch,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Local'),
            Tab(text: 'Online'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    final songProvider = Provider.of<SongProvider>(context);
    final results = _showOnlineResults
        ? songProvider.onlineSearchResults
        : _localSearchResults;
    final bool isLoading = _showOnlineResults
        ? songProvider.isSearchingOnline
        : _isSearching;

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for songs, artists, or albums',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type to start searching your music library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${_searchController.text}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: const Icon(Icons.music_note, size: 36),
          tileColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: _highlightText(
            Helper.getSongName(song.title),
            _searchController.text,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (song.artist.isNotEmpty)
                _highlightText(song.artist, _searchController.text),
              if (song.album.isNotEmpty)
                Text(
                  song.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
            ],
          ),
          isThreeLine: false,
          dense: true,
          trailing: Builder(
            builder: (context) {
              final isCurrentSong = context.select<AudioService, bool>(
                (audioService) => audioService.currentSong?.path == song.path,
              );

              if (!isCurrentSong) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.equalizer_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
