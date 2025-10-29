// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, String> video;
  final List<Map<String, String>> videoList;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.videoList,
    required this.initialIndex,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto';
  final List<String> _availableQualities = [
    'Auto',
    '1080p',
    '720p',
    '480p',
    '360p',
  ];
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentVideoIndex = widget.initialIndex;
    _initializePlayer();
  }

  void _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(
      File(widget.video['path']!),
    );

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      showControls: true,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      systemOverlaysOnEnterFullScreen: [
        SystemUiOverlay.top,
        SystemUiOverlay.bottom,
      ],
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    setState(() {
      _isPlaying = true;
    });
  }

  void _playNextVideo() {
    if (_currentVideoIndex < widget.videoList.length - 1) {
      _changeVideo(_currentVideoIndex + 1);
    }
  }

  void _playPreviousVideo() {
    if (_currentVideoIndex > 0) {
      _changeVideo(_currentVideoIndex - 1);
    }
  }

  void _changeVideo(int newIndex) async {
    setState(() {
      _currentVideoIndex = newIndex;
    });

    _chewieController?.dispose();
    await _videoPlayerController.dispose();

    _initializePlayer();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoPlayerController.play();
      } else {
        _videoPlayerController.pause();
      }
    });
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _videoPlayerController.setPlaybackSpeed(speed);
    });
  }

  void _changeQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
      // Here you would typically change the video source based on quality
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.videoList[_currentVideoIndex]['title'] ?? 'Video Player',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildSpeedSelector(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.high_quality),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildQualitySelector(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          _buildVideoInfo(),
          _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildSpeedSelector() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Playback Speed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            children: speeds.map((speed) {
              return ChoiceChip(
                label: Text('${speed}x'),
                selected: _playbackSpeed == speed,
                onSelected: (selected) {
                  if (selected) {
                    _changePlaybackSpeed(speed);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Quality',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._availableQualities.map((quality) {
            return ListTile(
              title: Text(quality),
              trailing: _selectedQuality == quality
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _changeQuality(quality);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.videoList[_currentVideoIndex]['title'] ?? 'No Title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.videoList[_currentVideoIndex]['artist'] ?? 'Unknown Artist',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            widget.videoList[_currentVideoIndex]['description'] ?? '',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 32),
            onPressed: _currentVideoIndex > 0 ? _playPreviousVideo : null,
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 48,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 32),
            onPressed: _currentVideoIndex < widget.videoList.length - 1
                ? _playNextVideo
                : null,
          ),
        ],
      ),
    );
  }
}
