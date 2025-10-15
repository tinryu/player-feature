import 'package:flutter/material.dart';
import '../utils/helper.dart';

class PlayerControlBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Function() onPlayPause;
  final Function() onPrevious;
  final Function() onNext;
  final Function() onShuffle;
  final Function() onRepeat;
  final Function(Duration) onSeek;
  final String songTitle;
  final String artistName;

  const PlayerControlBar({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
    required this.onSeek,

    this.songTitle = 'No song selected',
    this.artistName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.lightBlue],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 4),
          // Song info
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    songTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Controls
          const SizedBox(height: 4),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
            trackHeight: 2.0,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble(),
            min: 0,
            max: duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0,
            onChanged: (value) {
              onSeek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Helper.formatDuration(position),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              Text(
                Helper.formatDuration(duration),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle button
        IconButton(
          icon: const Icon(Icons.shuffle, size: 22),
          color: Colors.white,
          onPressed: onShuffle,
        ),
        const SizedBox(width: 12),

        // Previous button
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 30),
          color: Colors.white,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 12),

        // Play/Pause button
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
              color: Colors.white,
            ),
            onPressed: onPlayPause,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 12),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 30),
          color: Colors.white,
          onPressed: onNext,
        ),
        const SizedBox(width: 12),

        // Repeat button
        IconButton(
          icon: const Icon(Icons.repeat, size: 22),
          color: Colors.white,
          onPressed: onRepeat,
        ),
      ],
    );
  }
}
