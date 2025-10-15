class AudioFolder {
  final String path;
  final String name;
  final int songCount;

  AudioFolder({
    required this.path,
    required this.name,
    required this.songCount,
  });

  // Get folder name from path
  static String getFolderName(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }
}
