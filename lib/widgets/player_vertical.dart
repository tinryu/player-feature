import 'package:flutter/material.dart';
import 'package:playermusic1/utils/helper.dart';
import 'package:playermusic1/services/audio_service.dart';
// import 'package:playermusic1/widgets/sleep_timer_dialog.dart';

class PlayerVertical extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Function() onPlayPause;
  final Function() onPrevious;
  final Function() onNext;
  final Function() onShuffle;
  final Function() onRepeat;
  final String songTitle;
  final String artistName;
  final AudioService audioService;

  const PlayerVertical({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
    required this.audioService,
    this.songTitle = 'No song selected',
    this.artistName = '',
  });

  @override
  State<PlayerVertical> createState() => _PlayerVerticalState();
}

class _PlayerVerticalState extends State<PlayerVertical> {
  // void _showSleepTimerDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => SleepTimerDialog(
  //       currentTimerMinutes: widget.audioService.sleepTimerMinutes,
  //       onTimerSet: (minutes) {
  //         widget.audioService.setSleepTimer(minutes);
  //         if (mounted) {
  //           setState(() {});
  //         }
  //       },
  //     ),
  //   );
  // }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle button
        IconButton(
          icon: const Icon(Icons.shuffle, size: 22),
          color: Colors.white,
          onPressed: widget.onShuffle,
        ),
        const SizedBox(width: 12),

        // Previous button
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 30),
          color: Colors.white,
          onPressed: widget.onPrevious,
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
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
              color: Colors.white,
            ),
            onPressed: widget.onPlayPause,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 12),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 30),
          color: Colors.white,
          onPressed: widget.onNext,
        ),
        const SizedBox(width: 12),

        // Repeat button
        IconButton(
          icon: const Icon(Icons.repeat, size: 22),
          color: Colors.white,
          onPressed: widget.onRepeat,
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
                  widget.audioService.seek(
                    Duration(milliseconds: value.toInt()),
                  );
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
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art
            Container(
              width: 280,
              height: 280,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                size: 120,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            // Song title and sleep timer button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer for centering
                  Expanded(
                    child: Text(
                      Helper.getSongName(widget.songTitle),
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
                  // StreamBuilder<int>(
                  //   stream: widget.audioService.sleepTimerStream,
                  //   initialData: widget.audioService.sleepTimerMinutes,
                  //   builder: (context, snapshot) {
                  //     final timerMinutes = snapshot.data ?? 0;
                  //     return IconButton(
                  //       icon: Icon(
                  //         Icons.bedtime_outlined,
                  //         color: timerMinutes > 0
                  //             ? Colors.amber
                  //             : Colors.white70,
                  //         size: 28,
                  //       ),
                  //       onPressed: _showSleepTimerDialog,
                  //       tooltip: timerMinutes > 0
                  //           ? 'Sleep timer: $timerMinutes min'
                  //           : 'Set sleep timer',
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Progress bar (optional)
            _buildProgressBar(widget.position, widget.duration),
            const SizedBox(height: 20),
            // Player controls
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
}
