// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_player_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

enum SortOrder { az, za }

class _VideoScreenState extends State<VideoScreen> {
  bool _isLoading = false;
  bool _isGridView = false; // Toggle between grid and list view
  SortOrder _sortOrder = SortOrder.az; // Default sort order

  // List to store video files
  List<Map<String, String>> _videos = [];

  // Scan for video files on the device
  Future<void> _scanVideos() async {
    try {
      // Request appropriate permissions based on platform
      if (Platform.isAndroid) {
        // Handle Android permissions
        var status = await Permission.videos.request();
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          if (await Permission.storage.isPermanentlyDenied) {
            // Open app settings if permission is permanently denied
            await openAppSettings();
          }
          return;
        }
      } else if (Platform.isWindows) {
        // Common video directories on Windows
        final commonVideoDirs = [
          '${Platform.environment['USERPROFILE']}\\Downloads',
          '${Platform.environment['USERPROFILE']}\\Videos',
          '${Platform.environment['USERPROFILE']}\\Desktop',
        ];

        bool hasAccess = false;
        Directory? accessibleDir;

        // Try to find an accessible directory
        for (final dirPath in commonVideoDirs) {
          try {
            final dir = Directory(dirPath);
            if (await dir.exists()) {
              await dir.list().first;
              accessibleDir = dir;
              hasAccess = true;
              break;
            }
          } catch (e) {
            // Continue to next directory
            debugPrint('Cannot access $dirPath: $e');
          }
        }

        if (!hasAccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cannot access video directories. Please check your folder permissions.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // If we found an accessible directory, use it for scanning
        if (accessibleDir != null) {
          try {
            // Show loading indicator
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }

            // Scan for video files
            final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.mkv'];
            final List<Map<String, String>> videos = [];

            final files = accessibleDir.list(recursive: true);
            await for (final file in files) {
              if (file is File) {
                final path = file.path.toLowerCase();
                if (videoExtensions.any((ext) => path.endsWith(ext))) {
                  final videoFile = File(file.path);
                  final stat = await videoFile.stat();

                  videos.add({
                    'path': file.path,
                    'name': file.uri.pathSegments.last,
                    'size':
                        '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                    'modified': stat.modified.toString().substring(0, 16),
                  });
                }
              }

              // Update UI periodically during scan
              if (videos.length % 10 == 0 && mounted) {
                setState(() {
                  _videos = videos;
                });
              }
            }

            if (mounted) {
              setState(() {
                _videos = videos;
                _isLoading = false;
              });
            }
          } catch (e) {
            debugPrint('Error scanning videos: $e');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error scanning videos: ${e.toString()}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } else {
        // Handle other platforms (iOS, macOS, etc.)
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (await Permission.storage.isPermanentlyDenied) {
            // The user opted to never see the permission request dialog for this
            // app. The only way to change the permission's status now is to let
            // the user manually enable it in the system settings.
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Storage Permission Required'),
                  content: const Text(
                    'Please grant storage permission in app settings to scan for video files.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(context);
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Storage permission denied. Please grant permission to scan for video files.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
          return;
        }
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Define video file extensions to look for
      const videoExtensions = [
        '.mp4',
        '.mkv',
        '.avi',
        '.mov',
        '.wmv',
        '.flv',
        '.webm',
        '.3gp',
      ];

      // Common video directories to scan (Android)
      final commonDirs = [
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Videos',
      ];

      final List<Map<String, String>> foundVideos = [];

      // Scan common directories
      for (final dirPath in commonDirs) {
        try {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await for (final file in dir.list(
              recursive: true,
              followLinks: false,
            )) {
              if (file is File) {
                final path = file.path.toLowerCase();
                if (videoExtensions.any((ext) => path.endsWith(ext))) {
                  foundVideos.add({
                    'title': file.path.split('/').last,
                    'path': file.path,
                    'artist': 'Local File',
                    'description': 'Size: ${(await file.length()) ~/ 1024} KB',
                  });
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors for directories we can't access
          debugPrint('Error scanning directory $dirPath: $e');
        }
      }

      // Update the UI with found videos
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          _videos = foundVideos;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning videos: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Optionally load videos when screen initializes
    _scanVideos();
  }

  // Get sorted videos based on current sort order
  List<Map<String, String>> get _sortedVideos {
    final list = List<Map<String, String>>.from(_videos);
    list.sort((a, b) {
      if (_sortOrder == SortOrder.az) {
        return a['title']!.compareTo(b['title']!);
      } else {
        return b['title']!.compareTo(a['title']!);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sort and view controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _scanVideos,
                  icon: Icon(
                    Icons.folder_open_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                  label: Text(
                    'Folder',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                // Combined sort and view menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  position: PopupMenuPosition.under,
                  menuPadding: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    // Sort section
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Sort By',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sort_az',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 20,
                            color: _sortOrder == SortOrder.az
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text('A-Z'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sort_za',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 20,
                            color: _sortOrder == SortOrder.za
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text('Z-A'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    // View section
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'View As',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_grid',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 20,
                            color: _isGridView
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text('Grid View'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_list',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 20,
                            color: !_isGridView
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text('List View'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    setState(() {
                      switch (value) {
                        case 'sort_az':
                          _sortOrder = SortOrder.az;
                          break;
                        case 'sort_za':
                          _sortOrder = SortOrder.za;
                          break;
                        case 'view_grid':
                          _isGridView = true;
                          break;
                        case 'view_list':
                          _isGridView = false;
                          break;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _isGridView
                ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: _sortedVideos.length,
                    itemBuilder: (context, index) =>
                        _buildVideoItem(_sortedVideos[index], index, context),
                  )
                : ListView.builder(
                    itemCount: _sortedVideos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildVideoItem(
                        _sortedVideos[index],
                        index,
                        context,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoItem(
    Map<String, String> video,
    int index,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to video player screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              video: video,
              videoList: _videos,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: _isGridView
            ? _buildGridItem(video, index)
            : _buildListItem(video, index),
      ),
    );
  }

  Widget _buildGridItem(Map<String, String> video, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Container(
              color: Colors.redAccent,
              child: const Icon(
                Icons.play_circle_filled,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: _buildVideoInfo(video, index),
        ),
      ],
    );
  }

  Widget _buildListItem(Map<String, String> video, int index) {
    return Row(
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
          child: const Icon(
            Icons.play_circle_filled,
            size: 36,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildVideoInfo(video, index),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo(Map<String, String> video, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          video['artist'] ?? 'Unknown Artist',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        if (!_isGridView) ...[
          const SizedBox(height: 4),
          Text(
            video['description'] ?? 'No description available',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
