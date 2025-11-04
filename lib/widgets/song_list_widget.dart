import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/helper.dart';
import '../widgets/rotating_widget.dart';

class SongListWidget extends StatefulWidget {
  final List<Song> songs;
  final Function(Song) onSongSelected;
  final Animation<double> fadeAnimation;
  final Song? currentSong;

  const SongListWidget({
    super.key,
    required this.songs,
    required this.onSongSelected,
    required this.fadeAnimation,
    required this.currentSong,
  });

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  late final ScrollController _scrollController;
  final int _batchSize = 10;
  int _displayCount = 0;
  bool _isLoadingMore = false;
  late List<Song> _currentSongs;
  bool _hasMoreItems = true;

  @override
  void initState() {
    super.initState();
    _currentSongs = List.from(widget.songs);
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitialItems();
  }

  void _loadInitialItems() {
    final initialCount = math.min(_batchSize, _currentSongs.length);
    setState(() {
      _displayCount = initialCount;
      _hasMoreItems = initialCount < _currentSongs.length;
    });
  }

  @override
  void didUpdateWidget(SongListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update state if the songs list actually changed
    if (oldWidget.songs != widget.songs) {
      _currentSongs = List.from(widget.songs);
      _updateDisplayCount();
      _hasMoreItems = _displayCount < _currentSongs.length;
    }

    // When only currentSong changes, the widget will rebuild automatically
    // without calling setState, preventing interference with scroll events
  }

  void _updateDisplayCount() {
    setState(() {
      _displayCount = math.min(_batchSize, _currentSongs.length);
      _hasMoreItems = _displayCount < _currentSongs.length;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 0.8 * maxScroll; // Load more when 80% scrolled

    // Debug: Check if scroll is working
    // if (maxScroll > 0 && currentScroll > 0) {
    //   debugPrint(
    //     'Scrolling: ${currentScroll.toStringAsFixed(0)}/${maxScroll.toStringAsFixed(0)} (${(currentScroll / maxScroll * 100).toStringAsFixed(0)}%) - hasMore=$_hasMoreItems, isLoading=$_isLoadingMore, display=$_displayCount/${_currentSongs.length}',
    //   );
    // }

    if (!_isLoadingMore && _hasMoreItems && currentScroll >= threshold) {
      debugPrint('Loading more items...');
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;

      final newDisplayCount = _displayCount + _batchSize;
      final hasMore = newDisplayCount < _currentSongs.length;

      if (mounted) {
        setState(() {
          _displayCount = hasMore ? newDisplayCount : _currentSongs.length;
          _hasMoreItems = hasMore;
        });
      }
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) {
      return const Center(child: Text('No songs found'));
    }

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _displayCount + (_hasMoreItems ? 1 : 0),
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        cacheExtent: 500, // Cache items ahead for smoother scrolling
        itemBuilder: (context, index) {
          // Ensure we don't go out of bounds
          if (index >= _currentSongs.length) {
            return const SizedBox.shrink();
          }

          if (index >= _displayCount && _hasMoreItems) {
            return _buildLoadingIndicator();
          }

          final song = _currentSongs[index];
          final bool isCurrentSong = widget.currentSong?.path == song.path;

          // Use a key to help Flutter identify and reuse widgets efficiently
          return SongListItem(
            key: ValueKey(song.path),
            song: song,
            isCurrentSong: isCurrentSong,
            onTap: () => widget.onSongSelected(song),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _hasMoreItems
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

// Separate widget to prevent rebuilds from affecting scroll performance
class SongListItem extends StatelessWidget {
  final Song song;
  final bool isCurrentSong;
  final VoidCallback onTap;

  const SongListItem({
    super.key,
    required this.song,
    required this.isCurrentSong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildSongThumbnail(),
      title: Text(
        Helper.getSongName(song.title),
        style: TextStyle(
          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
          color: isCurrentSong ? Colors.redAccent : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  Widget _buildSongThumbnail() {
    return song.albumArt != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(song.albumArt!),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
            ),
          )
        : _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return SizedBox(
      width: 24,
      height: 24,
      child: isCurrentSong
          ? RotatingWidget(
              duration: const Duration(seconds: 2),
              effect: RotationEffect.pulse,
              curve: Curves.bounceInOut,
              child: Icon(Icons.graphic_eq, color: Colors.redAccent),
            )
          : const Icon(Icons.music_note),
    );
  }
}
