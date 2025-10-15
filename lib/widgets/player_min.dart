import 'package:flutter/material.dart';
import 'package:playermusic1/screens/detail_screen.dart';
import '../utils/helper.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

class PlayerMinBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Function() onPlayPause;
  final Function() onNext;
  final Function() onPrevious;
  final Function() onShuffle;
  final Function() onRepeat;
  final Function() onOpenFiles;
  final String songTitle;
  final Song? currentSong;
  final AudioService audioService;

  const PlayerMinBar({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
    required this.onOpenFiles,
    required this.currentSong,
    required this.audioService,
    this.songTitle = 'No song selected',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return DetailScreen(
                isPlaying: isPlaying,
                duration: duration,
                position: position,
                onPlayPause: onPlayPause,
                onPrevious: onPrevious,
                onNext: onNext,
                onShuffle: onShuffle,
                onRepeat: onRepeat,
                songTitle: songTitle,
                artistName: currentSong?.artist ?? '',
                audioService: audioService,
                animation: animation,
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
            Stack(
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
            SizedBox(width: 10),
            Expanded(
              child: Text(
                Helper.getSongName(songTitle),
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
              icon: isPlaying
                  ? const Icon(Icons.pause_rounded)
                  : const Icon(Icons.play_arrow_rounded),
              color: Colors.white,
              onPressed: onPlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
              onPressed: onNext,
            ),
            IconButton(
              icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
              onPressed: onOpenFiles,
            ),
          ],
        ),
      ),
    );
  }
}
