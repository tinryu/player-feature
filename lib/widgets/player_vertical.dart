import 'package:flutter/material.dart';
import 'package:playermusic1/utils/helper.dart';
import 'package:playermusic1/providers/audio_provider.dart';
// import 'package:playermusic1/widgets/sleep_timer_dialog.dart';
import 'rotating_widget.dart';

class PlayerVertical extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final AudioProvider audioProvider;

  const PlayerVertical({
    super.key,
    required this.position,
    required this.duration,
    required this.audioProvider,
  });

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Repeat button with state
        IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              // Main icon
              Icon(
                audioProvider.repeatMode == 0 ? Icons.repeat : Icons.repeat_one,
                size: 20,
                color: audioProvider.repeatMode > 0
                    ? Colors
                          .white // Highlight when repeat is active
                    : Colors.grey.shade500,
              ),
              // Small indicator for repeat one
              if (audioProvider.repeatMode == 1)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: audioProvider.toggleRepeat,
          tooltip: audioProvider.repeatMode == 0
              ? 'No repeat'
              : audioProvider.repeatMode == 1
              ? 'Repeat one'
              : 'Repeat all',
        ),
        // Previous button
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 25),
          color: Colors.white,
          onPressed: audioProvider.previous,
        ),

        // Play/Pause button
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              audioProvider.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 30,
              color: Colors.white,
            ),
            onPressed: audioProvider.togglePlayPause,
            padding: const EdgeInsets.all(12),
          ),
        ),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 25),
          color: Colors.white,
          onPressed: audioProvider.next,
        ),
        // Mute button
        IconButton(
          icon: Icon(
            audioProvider.isMuted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            size: 20,
            color: !audioProvider.isMuted ? Colors.grey.shade500 : Colors.white,
          ),
          onPressed: audioProvider.toggleMute,
        ),
      ],
    );
  }

  Widget _buildProgressBar(Duration position, Duration duration) {
    // Ensure we have valid duration to avoid division by zero
    final safeDuration = duration.inMilliseconds > 0
        ? duration
        : const Duration(seconds: 1);
    final safePosition = position.inMilliseconds > safeDuration.inMilliseconds
        ? safeDuration
        : position;

    return Column(
      children: [
        // Slider for progress
        Material(
          color: Colors.transparent,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              trackHeight: 2.0,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            ),
            child: Slider(
              value: safePosition.inMilliseconds.toDouble(),
              min: 0,
              max: safeDuration.inMilliseconds.toDouble(),
              onChanged: (value) {
                if (safeDuration.inMilliseconds > 0) {
                  audioProvider.seek(Duration(milliseconds: value.toInt()));
                }
              },
            ),
          ),
        ),

        // Time indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current position
              Text(
                Helper.formatDuration(safePosition),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              // Remaining time
              Text(
                '-${Helper.formatDuration(safeDuration - safePosition)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art
          RotatingWidget(
            isAnimating: audioProvider.isPlaying,
            duration: Duration(milliseconds: 10000),
            effect: RotationEffect.clockwise,
            curve: Curves.fastLinearToSlowEaseIn,
            child: audioProvider.isPlaying
                ? Container(
                    width: 220,
                    height: 220,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.cyclone_sharp,
                      size: 200,
                      color: Colors.red.shade700,
                    ),
                  )
                : Container(
                    width: 220,
                    height: 220,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 150,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Song title and sleep timer button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  Helper.getSongName(audioProvider.currentSong?.title ?? ''),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer button
              StreamBuilder<int>(
                stream: audioProvider.sleepTimerStream,
                builder: (context, snapshot) {
                  final minutesLeft = snapshot.data ?? 0;

                  if (minutesLeft > 0) {
                    // Show countdown timer
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            color: Colors.amber,
                            size: 16,
                          ),
                          Text(
                            '$minutesLeft',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar (optional)
          _buildProgressBar(position, duration),
          const SizedBox(height: 20),
          // Player controls
          _buildControlButtons(),
        ],
      ),
    );
  }
}
