import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../utils/helper.dart';

class SongListWidget extends StatelessWidget {
  final List<Song> songs;
  final AudioService audioService;
  final Animation<double> fadeAnimation;

  const SongListWidget({
    super.key,
    required this.songs,
    required this.audioService,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      stream: audioService.currentSongStream,
      builder: (context, snapshot) {
        final currentSong = snapshot.data;

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isCurrentSong = currentSong?.path == song.path;

            return ListTile(
              leading: isCurrentSong
                  ? FadeTransition(
                      opacity: fadeAnimation,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.graphic_eq, color: Colors.blue),
                      ),
                    )
                  : const Icon(Icons.music_note),
              title: Text(
                Helper.getSongName(song.title),
                style: TextStyle(
                  fontWeight: isCurrentSong
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCurrentSong ? Colors.blue : null,
                  fontSize: 16,
                ),
              ),
              onTap: () => audioService.playSong(song),
            );
          },
        );
      },
    );
  }
}
