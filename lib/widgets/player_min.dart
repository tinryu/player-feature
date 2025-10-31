import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/detail_screen.dart';
import '../utils/helper.dart';
import '../services/equalizer_service.dart';
import '../widgets/rotating_widget.dart';

class PlayerMinBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Function() onOpenFiles;
  final EqualizerService equalizerService;

  const PlayerMinBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onOpenFiles,
    required this.equalizerService,
  });

  @override
  State<PlayerMinBar> createState() => _PlayerMinBarState();
}

class _PlayerMinBarState extends State<PlayerMinBar>
    with SingleTickerProviderStateMixin {
  late AudioProvider audioProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    audioProvider = Provider.of<AudioProvider>(context);

    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant PlayerMinBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    audioProvider = Provider.of<AudioProvider>(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return DetailScreen(
                animation: animation,
                equalizerService: widget.equalizerService,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RotatingWidget(
              isAnimating: audioProvider.isPlaying,
              duration: const Duration(seconds: 2),
              effect: RotationEffect.clockwise,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.orange.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey[850],
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10),
            Expanded(
              child: Text(
                Helper.getSongName(
                  audioProvider.currentSong?.title ?? 'No song selected',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: audioProvider.isPlaying
                  ? const Icon(Icons.pause_rounded)
                  : const Icon(Icons.play_arrow_rounded),
              color: Colors.white,
              onPressed: audioProvider.togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
              onPressed: audioProvider.next,
            ),
            IconButton(
              icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
              onPressed: widget.onOpenFiles,
            ),
            SizedBox(width: 5),
            // Sleep timer countdown or equalizer icon
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
                  return Icon(
                    Icons.timer_off_rounded,
                    color: Colors.white,
                    size: 20,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
