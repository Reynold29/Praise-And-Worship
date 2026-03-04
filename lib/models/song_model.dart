import 'package:flutter/foundation.dart';

@immutable
class Song {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String? englishTitle;
  final String lyrics;
  final String? transLyrics;
  final String? chords;
  final String
      category; // May be 'english_data', 'english', 'kannada_data', or 'kannada'. Normalized for display in UI.
  final String? authorName;
  final String? genre;
  final String? keySignature;
  final int? bpm;
  final String? youtubeLink;

  const Song({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.englishTitle,
    required this.lyrics,
    this.transLyrics,
    this.chords,
    required this.category,
    this.authorName,
    this.genre,
    this.keySignature,
    this.bpm,
    this.youtubeLink,
  });

  factory Song.fromJson(Map<String, dynamic> json, {String? categoryOverride}) {
    String? createdAtStr = json['created_at'] as String?;
    String? updatedAtStr = json['updated_at'] as String?;
    return Song(
      id: json['id'].toString(),
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
          : DateTime.now(),
      title: json['title'] as String,
      englishTitle: json['english_title'] as String?,
      lyrics: json['lyrics'] as String,
      transLyrics: json['trans_lyrics'] as String?,
      chords: json['chords'] as String?,
      category:
          categoryOverride ?? json['category']?.toString() ?? 'unknown_data',
      authorName: json['author_name'] as String?,
      genre: json['genre'] as String?,
      keySignature: json['key_signature'] as String?,
      bpm: json['bpm'] as int?,
      youtubeLink: json['youtube_link'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'title': title,
        'english_title': englishTitle,
        'lyrics': lyrics,
        'trans_lyrics': transLyrics,
        'chords': chords,
        'category': category,
        'author_name': authorName,
        'genre': genre,
        'key_signature': keySignature,
        'bpm': bpm,
        'youtube_link': youtubeLink,
      };
}
