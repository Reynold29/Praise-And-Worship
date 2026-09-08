class Playlist {
  final String id;
  final String? userId; // nullable for local playlists
  final String name;
  final DateTime createdAt;
  final bool deleted;

  Playlist({
    required this.id,
    this.userId,
    required this.name,
    required this.createdAt,
    this.deleted = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'deleted': deleted,
    };
  }

  Playlist copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    bool? deleted,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
    );
  }
}

class PlaylistSong {
  final String id;
  final String playlistId;
  final String songId;
  final String category; // english, kannada, etc.
  final DateTime addedAt;

  PlaylistSong({
    required this.id,
    required this.playlistId,
    required this.songId,
    required this.category,
    required this.addedAt,
  });

  factory PlaylistSong.fromJson(Map<String, dynamic> json) {
    return PlaylistSong(
      id: json['id'] as String,
      playlistId: json['playlist_id'] as String,
      songId: json['song_id'] as String,
      category: json['category'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'song_id': songId,
      'category': category,
      'added_at': addedAt.toIso8601String(),
    };
  }

  PlaylistSong copyWith({
    String? id,
    String? playlistId,
    String? songId,
    String? category,
    DateTime? addedAt,
  }) {
    return PlaylistSong(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      songId: songId ?? this.songId,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
