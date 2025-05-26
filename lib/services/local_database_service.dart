import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'dart:math';
import '../models/song_model.dart';
import 'supabase_service.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();
  static const _dbName = 'songs_encrypted.db';
  static const _dbPasswordKey = 'db_encryption_key';
  static const _storage = FlutterSecureStorage();

  Database? _db;

  LocalDatabaseService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // Get or generate encryption key
    String? key = await _storage.read(key: _dbPasswordKey);
    if (key == null) {
      key = _generateRandomKey();
      await _storage.write(key: _dbPasswordKey, value: key);
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      password: key,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            lyrics TEXT NOT NULL,
            chords TEXT,
            author_name TEXT NOT NULL,
            language TEXT NOT NULL,
            genre TEXT,
            key_signature TEXT,
            bpm INTEGER,
            youtube_link TEXT,
            updated_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add chords column if upgrading from v1
          await db.execute('ALTER TABLE songs ADD COLUMN chords TEXT;');
        }
      },
    );
  }

  String _generateRandomKey() {
    // Generate a strong random key (32+ chars)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()-_=+[]{}|;:,.<>?';
    final rand = Random.secure();
    return List.generate(32, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  // --- CRUD & Sync Methods ---

  Future<void> upsertSongs(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert(
        'songs',
        _songToMap(song),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Song>> fetchAllSongs() async {
    final db = await database;
    final maps = await db.query('songs', orderBy: 'title COLLATE NOCASE ASC');
    return maps.map((map) => _songFromMap(map)).toList();
  }

  Future<void> deleteSongsNotInIdList(List<String> idsToKeep) async {
    final db = await database;
    if (idsToKeep.isEmpty) {
      await db.delete('songs');
    } else {
      final placeholders = List.filled(idsToKeep.length, '?').join(',');
      await db.delete('songs', where: 'id NOT IN ($placeholders)', whereArgs: idsToKeep);
    }
  }

  Future<void> clearAllSongs() async {
    final db = await database;
    await db.delete('songs');
  }

  /// Sync all songs from Supabase to the local encrypted DB
  Future<void> syncFromSupabase() async {
    try {
      // Fetch all songs from Supabase (adjust table/key as needed)
      List<Song> supabaseSongs = await SupabaseService.instance.getSongsByCategory('english_data');
      // Upsert all songs
      await upsertSongs(supabaseSongs);
      // Delete local songs not in Supabase
      final supabaseIds = supabaseSongs.map((s) => s.id).toList();
      await deleteSongsNotInIdList(supabaseIds);
    } catch (e) {
      print('Supabase sync failed: $e');
    }
  }

  // --- Song <-> Map helpers ---
  Map<String, dynamic> _songToMap(Song song) => {
    'id': song.id,
    'title': song.title,
    'lyrics': song.lyrics,
    'chords': song.chords,
    'author_name': song.authorName ?? '',
    'language': song.category, // If you use a dedicated language field, change this accordingly
    'genre': song.genre,
    'key_signature': song.keySignature,
    'bpm': song.bpm,
    'youtube_link': song.youtubeLink,
    'updated_at': song.updatedAt.toIso8601String(),
  };

  Song _songFromMap(Map<String, dynamic> map) => Song(
    id: map['id'] as String,
    createdAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    title: map['title'] as String,
    lyrics: map['lyrics'] as String,
    chords: map['chords'] as String?,
    category: map['language'] as String? ?? '', // If you use a dedicated language field, change this accordingly
    authorName: map['author_name'] as String?,
    genre: map['genre'] as String?,
    keySignature: map['key_signature'] as String?,
    bpm: map['bpm'] as int?,
    youtubeLink: map['youtube_link'] as String?,
  );
} 