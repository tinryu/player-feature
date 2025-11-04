import 'package:flutter/material.dart';
import '../models/audio_folder.dart';

class FolderListWidget extends StatelessWidget {
  final List<AudioFolder> folders;
  final Function(AudioFolder) onFolderTap;

  const FolderListWidget({
    super.key,
    required this.folders,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: Colors.grey.shade100,
                size: 30,
              ),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${folder.songCount} song${folder.songCount > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: Icon(Icons.add_rounded, color: Colors.grey.shade400),
            onTap: () => onFolderTap(folder),
          ),
        );
      },
    );
  }
}
