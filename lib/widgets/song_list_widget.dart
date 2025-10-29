import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/helper.dart';

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
    return Column(
      children: [
        Expanded(
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

              return ListTile(
                leading: isCurrentSong
                    ? FadeTransition(
                        opacity: widget.fadeAnimation,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: isCurrentSong
                              ? const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.redAccent,
                                )
                              : const Icon(Icons.graphic_eq),
                        ),
                      )
                    : const Icon(Icons.music_note),
                title: Text(
                  Helper.getSongName(song.title),
                  style: TextStyle(
                    fontWeight: isCurrentSong
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                    color: isCurrentSong ? Colors.redAccent : null,
                  ),
                ),
                tileColor: isCurrentSong
                    ? Colors.redAccent.withValues(alpha: 0.1)
                    : null,
                onTap: () => widget.onSongSelected(song),
              );
            },
          ),
        ),
      ],
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
