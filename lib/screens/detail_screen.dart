import 'package:flutter/material.dart';
import 'package:playermusic1/services/equalizer_service.dart';
import 'package:playermusic1/widgets/player_vertical.dart';
import 'package:provider/provider.dart';
import 'package:playermusic1/providers/audio_provider.dart';
import 'package:playermusic1/widgets/player_menu_bottom_sheet.dart';

class DetailScreen extends StatelessWidget {
  final Animation<double> animation;
  final EqualizerService equalizerService;
  const DetailScreen({
    super.key,
    required this.animation,
    required this.equalizerService,
  });
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    void showMenuBottomSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => PlayerMenuBottomSheet(
          audioProvider: audioProvider,
          equalizerService: equalizerService,
        ),
      );
    }

    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Positioned(
              bottom: Tween<double>(begin: 0, end: 0).animate(animation).value,
              left: Tween<double>(begin: 8, end: 0).animate(animation).value,
              right: Tween<double>(begin: 8, end: 0).animate(animation).value,
              top: Tween<double>(
                begin: MediaQuery.of(context).size.height - 80,
                end: 0,
              ).animate(animation).value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      Tween<double>(begin: 12, end: 0).animate(animation).value,
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
                  //     // Player controls
                  StreamBuilder<Duration>(
                    stream: audioProvider.positionStream,
                    builder: (context, positionSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: audioProvider.durationStream,
                        builder: (context, durationSnapshot) {
                          final duration =
                              durationSnapshot.data ?? Duration.zero;
                          final position =
                              positionSnapshot.data ?? Duration.zero;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          showMenuBottomSheet(context),
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: PlayerVertical(
                                  position: position,
                                  duration: duration,
                                  audioProvider: audioProvider,
                                ),
                              ),
                            ],
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
}
