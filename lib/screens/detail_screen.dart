import 'package:flutter/material.dart';
import 'package:playermusic1/widgets/player_vertical.dart';
import 'package:playermusic1/services/audio_service.dart';
import 'package:playermusic1/services/equalizer_service.dart';
import 'package:playermusic1/widgets/player_menu_bottom_sheet.dart';

class DetailScreen extends StatefulWidget {
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
  final EqualizerService equalizerService;
  final Animation<double> animation;

  const DetailScreen({
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
    required this.equalizerService,
    this.songTitle = 'No song selected',
    this.artistName = '',
    required this.animation,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerMenuBottomSheet(
        audioService: widget.audioService,
        equalizerService: widget.equalizerService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            return Positioned(
              bottom: Tween<double>(
                begin: 0,
                end: 0,
              ).animate(widget.animation).value,
              left: Tween<double>(
                begin: 8,
                end: 0,
              ).animate(widget.animation).value,
              right: Tween<double>(
                begin: 8,
                end: 0,
              ).animate(widget.animation).value,
              top: Tween<double>(
                begin: MediaQuery.of(context).size.height - 80,
                end: 0,
              ).animate(widget.animation).value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      Tween<double>(
                        begin: 12,
                        end: 0,
                      ).animate(widget.animation).value,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              height: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _showMenuBottomSheet,
                        icon: const Icon(Icons.more_horiz_rounded),
                        color: Colors.white,
                        iconSize: 28,
                      ),
                    ],
                  ),
                  // Add back button to collapse
                  GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Wrap PlayerVertical with StreamBuilder to listen to position/duration changes
                  StreamBuilder<Duration>(
                    stream: widget.audioService.positionStream,
                    builder: (context, positionSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: widget.audioService.durationStream,
                        builder: (context, durationSnapshot) {
                          return StreamBuilder<bool>(
                            stream: widget.audioService.isPlayingStream,
                            builder: (context, isPlayingSnapshot) {
                              return StreamBuilder(
                                stream: widget.audioService.currentSongStream,
                                builder: (context, songSnapshot) {
                                  final position =
                                      positionSnapshot.data ?? widget.position;
                                  final duration =
                                      durationSnapshot.data ?? widget.duration;
                                  final isPlaying =
                                      isPlayingSnapshot.data ??
                                      widget.isPlaying;
                                  final currentSong = songSnapshot.data;

                                  return Expanded(
                                    child: PlayerVertical(
                                      isPlaying: isPlaying,
                                      position: position,
                                      duration: duration,
                                      onPlayPause: widget.onPlayPause,
                                      onPrevious: widget.onPrevious,
                                      onNext: widget.onNext,
                                      onShuffle: widget.onShuffle,
                                      onRepeat: widget.onRepeat,
                                      audioService: widget.audioService,
                                      songTitle:
                                          currentSong?.title ??
                                          widget.songTitle,
                                      artistName:
                                          currentSong?.artist ??
                                          widget.artistName,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
