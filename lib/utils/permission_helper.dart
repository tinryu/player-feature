import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Check and request storage/audio permissions
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // No permission needed for other platforms
    }

    // For Android 13+ (API 33+), use audio permission
    // For older versions, use storage permission
    PermissionStatus status;

    // Try audio permission first (Android 13+)
    status = await Permission.audio.status;
    if (status.isDenied) {
      status = await Permission.audio.request();
    }

    // If audio permission is not available, try storage (Android 12 and below)
    if (!status.isGranted) {
      status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    }

    // Handle different permission states
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (context.mounted) {
        await _showPermissionDeniedDialog(context);
      }
      return false;
    } else {
      // Permission denied
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required to access music files',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Show dialog when permission is permanently denied
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Storage permission is required to access your music files. '
            'Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Check if permission is granted
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    // Check audio permission (Android 13+)
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) {
      return true;
    }

    // Check storage permission (Android 12 and below)
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Show permission rationale before requesting
  static Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Storage Access'),
              content: const Text(
                'This app needs access to your device storage to find and play music files. '
                'Your privacy is important - we only access audio files.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Deny'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
