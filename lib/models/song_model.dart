import 'package:flutter/foundation.dart';

@immutable
class Song {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String lyrics;
  final String? chords;
  final String category; // Assuming this matches categoryKey from CardModel
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
    required this.lyrics,
    this.chords,
    required this.category,
    this.authorName,
    this.genre,
    this.keySignature,
    this.bpm,
    this.youtubeLink,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String,
      lyrics: json['lyrics'] as String,
      chords: json['chords'] as String?,
      category: json['category'].toString(),
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
        'lyrics': lyrics,
        'chords': chords,
        'category': category,
        'author_name': authorName,
        'genre': genre,
        'key_signature': keySignature,
        'bpm': bpm,
        'youtube_link': youtubeLink,
      };
} 