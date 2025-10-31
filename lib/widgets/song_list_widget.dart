import 'dart:io';

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
  final ScrollController _scrollController = ScrollController();

  final int _batchSize = 100;
  int _displayCount = 0;
  bool _isLoadingMore = false;
  late List<Song> _currentSongs;

  @override
  void initState() {
    super.initState();
    _currentSongs = widget.songs;
    _updateDisplayCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SongListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songs != _currentSongs) {
      _currentSongs = widget.songs;
      _updateDisplayCount();
    }
  }

  void _updateDisplayCount() {
    setState(() {
      _displayCount = _batchSize < _currentSongs.length
          ? _batchSize
          : _currentSongs.length;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_displayCount < _currentSongs.length) {
        setState(() {
          _isLoadingMore = true;
        });

        // Simulate loading delay (you can remove this in production)
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        setState(() {
          _displayCount = (_displayCount + _batchSize).clamp(
            0,
            _currentSongs.length,
          );
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
        itemCount: _displayCount + 1, // +1 for loading indicator
        itemBuilder: (context, index) {
          if (index >= _displayCount && _isLoadingMore) {
            return _buildLoadingIndicator();
          }

          if (index >= _currentSongs.length && !_isLoadingMore) {
            return const SizedBox.shrink();
          }

          final song = _currentSongs[index];
          final bool isCurrentSong = widget.currentSong?.path == song.path;

          return _buildSongItem(song, isCurrentSong);
        },
      ),
    );
  }

  Widget _buildSongItem(Song song, bool isCurrentSong) {
    return ListTile(
      leading: _buildSongThumbnail(song, isCurrentSong),
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
      trailing: Text(
        Helper.formatDuration(song.duration),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => widget.onSongSelected(song),
    );
  }

  Widget _buildSongThumbnail(Song song, bool isCurrentSong) {
    return song.albumArt != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(song.albumArt!),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _buildDefaultThumbnail(isCurrentSong),
            ),
          )
        : _buildDefaultThumbnail(isCurrentSong);
  }

  Widget _buildDefaultThumbnail(bool isCurrentSong) {
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

  Widget _buildLoadingIndicator() {
    if (_displayCount >= _currentSongs.length) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
