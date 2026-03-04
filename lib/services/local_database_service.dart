import 'dart:io';
import '../utils/app_logger.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import '../models/song_model.dart';
import 'supabase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();

  // DB file names
  static const _dbName = 'songs_encrypted.db';
  static const _dbNameKannada = 'kannada_songs_encrypted.db';
  static const _dbNameOther = 'other_songs_encrypted.db';

  // Keys used in FlutterSecureStorage
  static const _dbPasswordKey = 'db_encryption_key';
  static const _dbPasswordKeyKannada = 'db_encryption_key_kannada';
  static const _dbPasswordKeyOther = 'db_encryption_key_other';

  // ─── Fixed app-level passphrase ──────────────────────────────────────────
  // Using a deterministic passphrase means the same key is used on every
  // install of this app version, so the DB can always be opened even after
  // a clean install or if FlutterSecureStorage is wiped.
  // If you ever need to rotate this key, bump the DB version and handle
  // the migration inside onUpgrade.
  static const _fixedPassphrase = 'wc_secure_app_2025!';

  static const _storage = FlutterSecureStorage();

  Database? _db;
  Database? _dbKannada;
  Database? _dbOther;

  LocalDatabaseService._();

  // ─── English DB ──────────────────────────────────────────────────────────

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        AppLogger.e('LocalDB', 'English DB init timed out');
        throw Exception('Database initialization timed out');
      },
    );
    return _db!;
  }

  Future<Database> _initDb() async {
    // Always store the fixed passphrase in secure storage so future code
    // that reads it will find a consistent value.
    await _storage.write(key: _dbPasswordKey, value: _fixedPassphrase);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return _openOrRecreateDb(
        path: path, key: _fixedPassphrase, dbType: 'english');
  }

  // ─── Kannada DB ──────────────────────────────────────────────────────────

  Future<Database> get kannadaDatabase async {
    if (_dbKannada != null) return _dbKannada!;
    _dbKannada = await _initKannadaDb().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        AppLogger.e('LocalDB', 'Kannada DB init timed out');
        throw Exception('Kannada database initialization timed out');
      },
    );
    return _dbKannada!;
  }

  Future<Database> _initKannadaDb() async {
    await _storage.write(key: _dbPasswordKeyKannada, value: _fixedPassphrase);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbNameKannada);
    return _openOrRecreateDb(
        path: path, key: _fixedPassphrase, dbType: 'kannada');
  }

  // ─── Other Languages DB ──────────────────────────────────────────────────

  Future<Database> get otherDatabase async {
    if (_dbOther != null) return _dbOther!;
    _dbOther = await _initOtherDb().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        AppLogger.e('LocalDB', 'Other DB init timed out');
        throw Exception('Other database initialization timed out');
      },
    );
    return _dbOther!;
  }

  Future<Database> _initOtherDb() async {
    await _storage.write(key: _dbPasswordKeyOther, value: _fixedPassphrase);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbNameOther);
    return _openOrRecreateDb(
        path: path, key: _fixedPassphrase, dbType: 'other');
  }

  // ─── Recovery wrapper ────────────────────────────────────────────────────
  // If opening the DB fails (wrong key from a previous random key, or corruption),
  // we delete the file and open a fresh empty DB. Data will be re-synced from
  // Supabase on the next sync cycle — nothing is permanently lost.
  Future<Database> _openOrRecreateDb({
    required String path,
    required String key,
    required String dbType,
  }) async {
    try {
      return await _doOpenDb(path: path, key: key);
    } catch (e) {
      AppLogger.e('LocalDB', 'Failed to open DB at $path', e);
      AppLogger.d('LocalDB', 'Deleting corrupt DB and recreating...');

      // Nullify the cached handle so the next `get database` call re-inits
      if (dbType == 'kannada') {
        _dbKannada = null;
      } else if (dbType == 'other') {
        _dbOther = null;
      } else {
        _db = null;
      }

      // Delete the bad file
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        AppLogger.d('LocalDB', 'Deleted old DB file: $path');
      }

      // Open a fresh empty DB
      try {
        return await _doOpenDb(path: path, key: key);
      } catch (e2) {
        AppLogger.e(
            'LocalDB', 'CRITICAL: Could not create fresh DB at $path', e2);
        rethrow;
      }
    }
  }

  Future<Database> _doOpenDb({required String path, required String key}) {
    return openDatabase(
      path,
      password: key,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            english_title TEXT,
            lyrics TEXT NOT NULL,
            trans_lyrics TEXT,
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
          await db.execute('ALTER TABLE songs ADD COLUMN chords TEXT;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE songs ADD COLUMN trans_lyrics TEXT;');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE songs ADD COLUMN english_title TEXT;');
        }
      },
    );
  }

  // ─── CRUD & Sync ─────────────────────────────────────────────────────────

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
    try {
      final db = await database;
      final maps = await db.query('songs', orderBy: 'title COLLATE NOCASE ASC');
      return maps.map((map) => _songFromMap(map)).toList();
    } catch (e) {
      AppLogger.e('LocalDB', 'Error fetching English songs', e);
      return [];
    }
  }

  Future<void> deleteSongsNotInIdList(List<String> idsToKeep) async {
    final db = await database;
    if (idsToKeep.isEmpty) {
      await db.delete('songs');
    } else {
      final placeholders = List.filled(idsToKeep.length, '?').join(',');
      await db.delete('songs',
          where: 'id NOT IN ($placeholders)', whereArgs: idsToKeep);
    }
  }

  Future<void> clearAllSongs() async {
    final db = await database;
    await db.delete('songs');
  }

  /// Sync English songs from Supabase to the local encrypted DB.
  Future<void> syncFromSupabase() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        AppLogger.d('LocalDB', 'No internet, skipping English sync.');
        return;
      }

      List<Song> supabaseSongs =
          await SupabaseService.instance.getSongsByCategory('english_data');
      await upsertSongs(supabaseSongs);
      final supabaseIds = supabaseSongs.map((s) => s.id).toList();
      await deleteSongsNotInIdList(supabaseIds);
      AppLogger.d('LocalDB', 'Synced ${supabaseSongs.length} English songs.');
    } catch (e) {
      AppLogger.e('LocalDB', 'English sync failed', e);
    }
  }

  // ─── Kannada CRUD & Sync ─────────────────────────────────────────────────

  Future<void> upsertKannadaSongs(List<Song> songs) async {
    final db = await kannadaDatabase;
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

  Future<List<Song>> fetchAllKannadaSongs() async {
    try {
      final db = await kannadaDatabase;
      final maps = await db.query('songs', orderBy: 'title COLLATE NOCASE ASC');
      return maps.map((map) => _songFromMap(map)).toList();
    } catch (e) {
      AppLogger.e('LocalDB', 'Error fetching Kannada songs', e);
      return [];
    }
  }

  Future<void> clearAllKannadaSongs() async {
    final db = await kannadaDatabase;
    await db.delete('songs');
  }

  Future<void> syncKannadaFromSupabase() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        AppLogger.d('LocalDB', 'No internet, skipping Kannada sync.');
        return;
      }

      List<Song> supabaseSongs =
          await SupabaseService.instance.getSongsByCategory('kannada_data');
      await upsertKannadaSongs(supabaseSongs);
      final supabaseIds = supabaseSongs.map((s) => s.id).toList();
      final db = await kannadaDatabase;
      if (supabaseIds.isEmpty) {
        await db.delete('songs');
      } else {
        final placeholders = List.filled(supabaseIds.length, '?').join(',');
        await db.delete('songs',
            where: 'id NOT IN ($placeholders)', whereArgs: supabaseIds);
      }
      AppLogger.d('LocalDB', 'Synced ${supabaseSongs.length} Kannada songs.');
    } catch (e) {
      AppLogger.e('LocalDB', 'Kannada sync failed', e);
    }
  }

  // ─── Other Languages CRUD & Sync ─────────────────────────────────────────

  Future<void> upsertOtherSongs(List<Song> songs) async {
    final db = await otherDatabase;
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

  Future<List<Song>> fetchAllOtherSongs() async {
    try {
      final db = await otherDatabase;
      final maps = await db.query('songs', orderBy: 'title COLLATE NOCASE ASC');
      return maps.map((map) => _songFromMap(map)).toList();
    } catch (e) {
      AppLogger.e('LocalDB', 'Error fetching Other songs', e);
      return [];
    }
  }

  Future<void> clearAllOtherSongs() async {
    final db = await otherDatabase;
    await db.delete('songs');
  }

  Future<void> syncOtherFromSupabase() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        AppLogger.d('LocalDB', 'No internet, skipping Other sync.');
        return;
      }

      List<Song> supabaseSongs =
          await SupabaseService.instance.getSongsByCategory('other_data');

      await upsertOtherSongs(supabaseSongs);
      final supabaseIds = supabaseSongs.map((s) => s.id).toList();
      final db = await otherDatabase;
      if (supabaseIds.isEmpty) {
        await db.delete('songs');
      } else {
        final placeholders = List.filled(supabaseIds.length, '?').join(',');
        await db.delete('songs',
            where: 'id NOT IN ($placeholders)', whereArgs: supabaseIds);
      }
      AppLogger.d('LocalDB', 'Synced ${supabaseSongs.length} Other songs.');
    } catch (e) {
      AppLogger.e('LocalDB', 'Other sync failed', e);
    }
  }

  /// Cleans up spurious English songs that crept into the Kannada table.
  Future<void> removeUnwantedKannadaSongs() async {
    final db = await kannadaDatabase;
    await db.delete(
      'songs',
      where:
          "(LOWER(title) LIKE ? OR LOWER(title) LIKE ? OR LOWER(title) LIKE ?) OR (LOWER(language) NOT IN (?, ?))",
      whereArgs: [
        '%search christian lyrics%',
        '%search christian%',
        '%christian lyrics%',
        'kannada',
        'kannada_data',
      ],
    );
  }

  // ─── Map helpers ─────────────────────────────────────────────────────────

  Map<String, dynamic> _songToMap(Song song) => {
        'id': song.id,
        'title': song.title,
        'english_title': song.englishTitle,
        'lyrics': song.lyrics,
        'trans_lyrics': song.transLyrics,
        'chords': song.chords,
        'author_name': song.authorName ?? '',
        'language': song.category,
        'genre': song.genre,
        'key_signature': song.keySignature,
        'bpm': song.bpm,
        'youtube_link': song.youtubeLink,
        'updated_at': song.updatedAt.toIso8601String(),
      };

  Song _songFromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      createdAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      title: map['title'] as String,
      englishTitle: map['english_title'] as String?,
      lyrics: map['lyrics'] as String,
      transLyrics: map['trans_lyrics'] as String?,
      chords: map['chords'] as String?,
      category: (map['language'] as String? ?? 'unknown_data'),
      authorName: map['author_name'] as String?,
      genre: map['genre'] as String?,
      keySignature: map['key_signature'] as String?,
      bpm: map['bpm'] as int?,
      youtubeLink: map['youtube_link'] as String?,
    );
  }
}
