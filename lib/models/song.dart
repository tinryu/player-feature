class Song {
  final String title;
  final String artist;
  final String path;
  final String album;
  final Duration duration;
  final String? albumArt;
  final String? genre;
  final int? trackNumber;
  final int? year;
  final bool isOnline;
  final String? onlineId;
  DateTime lastPlayed;

  Song({
    required this.title,
    required this.artist,
    required this.path,
    this.album = 'Unknown Album',
    Duration? duration,
    this.albumArt,
    this.genre,
    this.trackNumber,
    this.year,
    this.isOnline = false,
    this.onlineId,
    DateTime? lastPlayed,
  }) : duration = duration ?? Duration.zero,
       lastPlayed = lastPlayed ?? DateTime.now();

  Song copyWith({
    String? title,
    String? artist,
    String? path,
    String? album,
    Duration? duration,
    String? albumArt,
    String? genre,
    int? trackNumber,
    int? year,
    bool? isOnline,
    String? onlineId,
    DateTime? lastPlayed,
  }) {
    return Song(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      path: path ?? this.path,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      genre: genre ?? this.genre,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      isOnline: isOnline ?? this.isOnline,
      onlineId: onlineId ?? this.onlineId,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  factory Song.fromFile(String path) {
    final fileName = path.split('/').last;
    final name = fileName.split('.').first;

    return Song(
      title: name,
      artist: 'Unknown Artist',
      path: path,
      album: 'Unknown Album',
      duration: Duration.zero,
    );
  }

  // Convert Song to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'path': path,
      'album': album,
      'duration': duration.inMilliseconds,
      'albumArt': albumArt,
      'genre': genre,
      'trackNumber': trackNumber,
      'year': year,
      'isOnline': isOnline,
      'onlineId': onlineId,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  // Create Song from JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] as String,
      artist: json['artist'] as String,
      path: json['path'] as String,
      album: json['album'] as String? ?? 'Unknown Album',
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      albumArt: json['albumArt'] as String?,
      genre: json['genre'] as String?,
      trackNumber: json['trackNumber'] as int?,
      year: json['year'] as int?,
      isOnline: json['isOnline'] as bool? ?? false,
      onlineId: json['onlineId'] as String?,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'] as String)
          : DateTime.now(),
    );
  }
}
