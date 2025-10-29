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

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Song> _searchResults = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Load songs if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final songProvider = context.read<SongProvider>();
      if (songProvider.songs.isEmpty) {
        songProvider.loadSongs();
      }
    });
  }

  void _performSearch(String query) {
    // Cancel any previous debounce timer
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Set up debounce timer (300ms)
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final songProvider = context.read<SongProvider>();
      setState(() {
        _searchResults = songProvider.searchSongs(query);
        _isSearching = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          margin: const EdgeInsets.symmetric(horizontal: 8),
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
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
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

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
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
