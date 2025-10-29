import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

class Helper {
  /// Extracts song name from file path and removes extension
  static String getSongName(String path) {
    try {
      String fileName = path.split(Platform.pathSeparator).last;
      if (fileName.contains('.')) {
        fileName = fileName.substring(0, fileName.lastIndexOf('.'));
      }
      return fileName;
    } catch (e) {
      return path;
    }
  }

  /// Formats duration in milliseconds to mm:ss format
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Shows a snackbar with the given message
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        margin: EdgeInsets.zero,
        content: Row(
          children: [
            Text(message, style: TextStyle(color: Colors.black)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
      ),
    );
  }

  /// Shows a confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = 'CANCEL',
    String confirmText = 'CONFIRM',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor ?? Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Checks if file is an audio file based on extension
  static bool isAudioFile(String path) {
    final audioExtensions = ['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'];
    return audioExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  /// Gets file size in readable format
  static String getFileSize(File file, {int decimals = 1}) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
