import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';
import '../utils/app_logger.dart';
import 'supabase_service.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();

  LocalDatabaseService._();

  List<Song>? _englishCache;
  List<Song>? _kannadaCache;
  List<Song>? _otherCache;

  Future<String> _getFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  bool _isOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.length == 1 && results.first == ConnectivityResult.none;
  }

  void invalidateCache({String? category}) {
    if (category == null) {
      _englishCache = null;
      _kannadaCache = null;
      _otherCache = null;
      return;
    }
    final c = category.toLowerCase();
    if (c.contains('english')) {
      _englishCache = null;
    } else if (c.contains('kannada')) {
      _kannadaCache = null;
    } else {
      _otherCache = null;
    }
  }

  Future<List<Song>> _fetchSongsFromFile(String fileName) async {
    try {
      final path = await _getFilePath(fileName);
      final file = File(path);
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final List<Song> validSongs = [];
      for (int i = 0; i < jsonList.length; i++) {
        try {
          final map = jsonList[i] as Map<String, dynamic>;
          validSongs.add(Song.fromJson(map));
        } catch (e) {
          AppLogger.e('LocalDB',
              'Failed to parse song at index $i: $e\nData: ${jsonList[i]}');
        }
      }
      return validSongs;
    } catch (e, stacktrace) {
      AppLogger.e(
          'LocalDB', 'Error reading JSON file $fileName: $e\n$stacktrace');
      return [];
    }
  }

  Future<void> _syncCategory(String supabaseCategory, String fileName,
      {bool forceFullResync = false, bool throwOnError = false}) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (_isOffline(connectivity)) {
        if (forceFullResync) throw Exception('No internet connection');
        AppLogger.d('LocalDB', 'No internet, skipping $supabaseCategory sync.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncKey = 'last_sync_$supabaseCategory';
      final lastSyncMillis = prefs.getInt(lastSyncKey) ?? 0;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;

      final path = await _getFilePath(fileName);
      final file = File(path);

      if (!forceFullResync && (nowMillis - lastSyncMillis) < 86400000) {
        if (await file.exists()) {
          AppLogger.d('LocalDB',
              'Skipping $supabaseCategory sync (synced < 24h ago and file exists).');
          return;
        }
      }

      final List<Song> supabaseSongs =
          await SupabaseService.instance.getSongsByCategory(supabaseCategory);

      if (supabaseSongs.isEmpty && !forceFullResync) {
        AppLogger.w('LocalDB',
            '$supabaseCategory sync returned 0 rows; keeping local file cache.');
        return;
      }

      final List<Map<String, dynamic>> jsonList =
          supabaseSongs.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
      await prefs.setInt(lastSyncKey, nowMillis);
      invalidateCache(category: supabaseCategory);

      AppLogger.d('LocalDB',
          'Synced ${supabaseSongs.length} songs from $supabaseCategory to $fileName');
    } catch (e) {
      AppLogger.e('LocalDB', 'Sync failed for $supabaseCategory', e);
      if (throwOnError) rethrow;
    }
  }

  Future<void> _deleteFile(String fileName) async {
    final path = await _getFilePath(fileName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Local-first: return disk/memory cache. Only hits network if [allowNetwork]
  /// and the local file is empty.
  Future<List<Song>> fetchAllSongs({bool allowNetwork = true}) async {
    if (_englishCache != null) return _englishCache!;
    final songs = await _fetchSongsFromFile('english_data.json');
    if (songs.isNotEmpty) {
      _englishCache = songs;
      return songs;
    }
    if (!allowNetwork) return const [];

    final connectivity = await Connectivity().checkConnectivity();
    if (_isOffline(connectivity)) {
      AppLogger.w('LocalDB', 'English cache empty and offline — returning [].');
      return const [];
    }

    AppLogger.w('LocalDB',
        'Local english_data.json empty — fetching from Supabase once...');
    await syncFromSupabase(forceFullResync: true);
    final refreshed = await _fetchSongsFromFile('english_data.json');
    _englishCache = refreshed;
    return refreshed;
  }

  Future<void> syncFromSupabase(
      {bool forceFullResync = false, bool throwOnError = false}) async {
    await _syncCategory('english_data', 'english_data.json',
        forceFullResync: forceFullResync, throwOnError: throwOnError);
  }

  Future<void> clearAllSongs() async {
    await _deleteFile('english_data.json');
    _englishCache = null;
  }

  Future<List<Song>> fetchAllKannadaSongs({bool allowNetwork = true}) async {
    List<Song> songs;
    if (_kannadaCache != null) {
      songs = _kannadaCache!;
    } else {
      songs = await _fetchSongsFromFile('kannada_data.json');
      if (songs.isEmpty && allowNetwork) {
        final connectivity = await Connectivity().checkConnectivity();
        if (!_isOffline(connectivity)) {
          AppLogger.w('LocalDB',
              'Local kannada_data.json empty — fetching from Supabase once...');
          await syncKannadaFromSupabase(forceFullResync: true);
          songs = await _fetchSongsFromFile('kannada_data.json');
        }
      }
      _kannadaCache = songs;
    }

    return songs.where((s) {
      final titleLower = s.title.toLowerCase();
      if (titleLower.contains('search christian') ||
          titleLower.contains('christian lyrics')) {
        return false;
      }
      if (s.category.toLowerCase() != 'kannada' &&
          s.category.toLowerCase() != 'kannada_data') {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> syncKannadaFromSupabase(
      {bool forceFullResync = false, bool throwOnError = false}) async {
    await _syncCategory('kannada_data', 'kannada_data.json',
        forceFullResync: forceFullResync, throwOnError: throwOnError);
  }

  Future<void> removeUnwantedKannadaSongs() async {}

  Future<void> clearAllKannadaSongs() async {
    await _deleteFile('kannada_data.json');
    _kannadaCache = null;
  }

  Future<List<Song>> fetchAllOtherSongs({bool allowNetwork = true}) async {
    if (_otherCache != null) return _otherCache!;
    var songs = await _fetchSongsFromFile('other_data.json');
    if (songs.isEmpty && allowNetwork) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!_isOffline(connectivity)) {
        await syncOtherFromSupabase(forceFullResync: true);
        songs = await _fetchSongsFromFile('other_data.json');
      }
    }
    _otherCache = songs;
    return songs;
  }

  Future<void> updateLocalSong(
      String table, Map<String, dynamic> updated) async {
    final fileName = table.endsWith('.json') ? table : '$table.json';
    final path = await _getFilePath(fileName);
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Local song cache is missing ($fileName).');
    }

    final List<dynamic> jsonList = jsonDecode(await file.readAsString());
    final songId = updated['id'].toString();
    var found = false;
    for (int i = 0; i < jsonList.length; i++) {
      final row = Map<String, dynamic>.from(jsonList[i] as Map);
      if (row['id'].toString() == songId) {
        row.addAll(Map<String, dynamic>.from(updated)..remove('id'));
        row['updated_at'] = DateTime.now().toUtc().toIso8601String();
        jsonList[i] = row;
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception('Song $songId was not found in local cache.');
    }
    await file.writeAsString(jsonEncode(jsonList));
    invalidateCache(category: table);
  }

  Future<Map<String, dynamic>?> getSongById(String table, String id) async {
    final fileName = table.endsWith('.json') ? table : '$table.json';
    final songs = await _fetchSongsFromFile(fileName);
    try {
      final song = songs.firstWhere((s) => s.id.toString() == id);
      return song.toJson();
    } catch (_) {
      return null;
    }
  }

  Future<Song?> fetchSongById(String lang, String id) async {
    List<Song> songs;
    if (lang == 'english' || lang == 'english_data') {
      songs = await fetchAllSongs();
    } else if (lang == 'kannada' || lang == 'kannada_data') {
      songs = await fetchAllKannadaSongs();
    } else {
      songs = await fetchAllOtherSongs();
    }
    try {
      return songs.firstWhere((s) => s.id.toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> syncOtherFromSupabase(
      {bool forceFullResync = false, bool throwOnError = false}) async {
    await _syncCategory('other_data', 'other_data.json',
        forceFullResync: forceFullResync, throwOnError: throwOnError);
  }

  Future<void> clearAllOtherSongs() async {
    await _deleteFile('other_data.json');
    _otherCache = null;
  }

  /// One coordinated sync: parallel categories, no double full-resync on boot.
  Future<void> syncAllCategories({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    const lastFullSyncKey = 'last_full_sync_all';
    final lastSyncMillis = prefs.getInt(lastFullSyncKey) ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    const threeDaysMs = 259200000;

    if (!force && (nowMillis - lastSyncMillis) <= threeDaysMs) {
      // Still allow light per-file 24h syncs when files missing.
      await Future.wait([
        syncFromSupabase(),
        syncKannadaFromSupabase(),
        syncOtherFromSupabase(),
      ]);
      return;
    }

    AppLogger.d('LocalDB', 'Starting coordinated full sync...');
    try {
      await Future.wait([
        syncFromSupabase(forceFullResync: true),
        syncKannadaFromSupabase(forceFullResync: true),
        syncOtherFromSupabase(forceFullResync: true),
      ]);
      await prefs.setInt(lastFullSyncKey, nowMillis);
      AppLogger.d('LocalDB', 'Coordinated full sync completed.');
    } catch (e) {
      AppLogger.e('LocalDB', 'Coordinated full sync failed', e);
    }
  }

  void triggerBackgroundSync(String category) {
    AppLogger.d('LocalDB', 'Triggering background sync for: $category');
    if (category.contains('kannada')) {
      syncKannadaFromSupabase();
    } else if (category.contains('english')) {
      syncFromSupabase();
    } else {
      syncOtherFromSupabase();
    }
  }
}
