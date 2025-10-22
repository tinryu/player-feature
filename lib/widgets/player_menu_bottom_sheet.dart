import 'package:flutter/material.dart';
import 'package:playermusic1/services/audio_service.dart';
import 'package:playermusic1/services/equalizer_service.dart';
import 'package:playermusic1/widgets/sleep_timer_dialog.dart';
import 'package:playermusic1/widgets/equalizer_dialog.dart';

class PlayerMenuBottomSheet extends StatelessWidget {
  final AudioService audioService;
  final EqualizerService equalizerService;

  const PlayerMenuBottomSheet({
    super.key,
    required this.audioService,
    required this.equalizerService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Menu items
            SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.access_time_rounded,
              title: 'Sleep Timer',
              onTap: () {
                Navigator.pop(context);
                _showSleepTimer(context);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.equalizer_rounded,
              title: 'Equalizer',
              onTap: () {
                Navigator.pop(context);
                _showEqualizer(context);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Song Info',
              onTap: () {
                Navigator.pop(context);
                _showSongInfo(context);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SleepTimerDialog(
        currentTimerMinutes: audioService.sleepTimerMinutes,
        onTimerSet: (minutes) {
          audioService.setSleepTimer(minutes);
        },
      ),
    );
  }

  void _showSongInfo(BuildContext context) {
    final currentSong = audioService.currentSong;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Song Info', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Title', currentSong?.title ?? 'Unknown'),
            _buildInfoRow('Artist', currentSong?.artist ?? 'Unknown'),
            _buildInfoRow('Album', currentSong?.album ?? 'Unknown'),
            _buildInfoRow(
              'Duration',
              _formatDuration(currentSong?.duration ?? Duration.zero),
            ),
            _buildInfoRow('Path', currentSong?.path ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _showEqualizer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EqualizerDialog(equalizerService: equalizerService),
    );
  }

  // void _showComingSoon(BuildContext context, String feature) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$feature - Coming soon!'),
  //       duration: const Duration(seconds: 2),
  //       backgroundColor: const Color(0xFF2D2D2D),
  //     ),
  //   );
  // }
}
