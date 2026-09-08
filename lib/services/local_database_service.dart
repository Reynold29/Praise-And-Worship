import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/song_model.dart';
import 'supabase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();

  LocalDatabaseService._();

  Future<String> _getFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  bool _isOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.length == 1 && results.first == ConnectivityResult.none;
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
        } catch (e, stacktrace) {
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

      // If not forced and it's been less than 24 hours, skip background sync to save bandwidth
      // HOWEVER, if the file doesn't actually exist (e.g. user cleared DB), we must sync anyway.
      if (!forceFullResync && (nowMillis - lastSyncMillis) < 86400000) {
        if (await file.exists()) {
          AppLogger.d('LocalDB',
              'Skipping $supabaseCategory sync (synced < 24h ago and file exists).');
          return;
        }
      }

      List<Song> supabaseSongs =
          await SupabaseService.instance.getSongsByCategory(supabaseCategory);

      if (supabaseSongs.isEmpty && !forceFullResync) {
        AppLogger.w('LocalDB',
            '$supabaseCategory sync returned 0 rows; keeping local file cache.');
        return;
      }

      final List<Map<String, dynamic>> jsonList =
          supabaseSongs.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await file.writeAsString(jsonString);
      await prefs.setInt(lastSyncKey, nowMillis);

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

  // ─── English ─────────────────────────────────────────────────────────────

  Future<List<Song>> fetchAllSongs() async {
    final songs = await _fetchSongsFromFile('english_data.json');
    if (songs.isEmpty) {
      AppLogger.w('LocalDB',
          'Local english_data.json was empty. Forcing instant synchronous fetch from Supabase...');
      await syncFromSupabase(forceFullResync: true);
      return await _fetchSongsFromFile('english_data.json');
    }
    return songs;
  }

  Future<void> syncFromSupabase(
      {bool forceFullResync = false, bool throwOnError = false}) async {
    await _syncCategory('english_data', 'english_data.json',
        forceFullResync: forceFullResync, throwOnError: throwOnError);
  }

  Future<void> clearAllSongs() async {
    await _deleteFile('english_data.json');
  }

  // ─── Kannada ─────────────────────────────────────────────────────────────

  Future<List<Song>> fetchAllKannadaSongs() async {
    List<Song> songs = await _fetchSongsFromFile('kannada_data.json');
    if (songs.isEmpty) {
      AppLogger.w('LocalDB',
          'Local kannada_data.json was empty. Forcing instant synchronous fetch from Supabase...');
      await syncKannadaFromSupabase(forceFullResync: true);
      songs = await _fetchSongsFromFile('kannada_data.json');
    }

    return songs.where((s) {
      final titleLower = s.title.toLowerCase();
      if (titleLower.contains('search christian') ||
          titleLower.contains('christian lyrics')) return false;
      if (s.category.toLowerCase() != 'kannada' &&
          s.category.toLowerCase() != 'kannada_data') return false;
      return true;
    }).toList();
  }

  Future<void> syncKannadaFromSupabase(
      {bool forceFullResync = false, bool throwOnError = false}) async {
    await _syncCategory('kannada_data', 'kannada_data.json',
        forceFullResync: forceFullResync, throwOnError: throwOnError);
  }

  Future<void> removeUnwantedKannadaSongs() async {
    // Handled purely in fetchAllKannadaSongs via filtering, saving complex file rewrites.
  }

  Future<void> clearAllKannadaSongs() async {
    await _deleteFile('kannada_data.json');
  }

  // ─── Other Languages ─────────────────────────────────────────────────────

  Future<List<Song>> fetchAllOtherSongs() async {
    return _fetchSongsFromFile('other_data.json');
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
  }

  // ─── Bulk / Periodic Sync ──────────────────────────────────────────────

  /// Checks if a full sync is needed (every 3 days) and runs it if so.
  Future<void> syncAllCategories({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    const lastFullSyncKey = 'last_full_sync_all';
    final lastSyncMillis = prefs.getInt(lastFullSyncKey) ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    // 3 days = 3 * 24 * 60 * 60 * 1000 = 259,200,000 ms
    const threeDaysMs = 259200000;

    if (force || (nowMillis - lastSyncMillis) > threeDaysMs) {
      AppLogger.d('LocalDB', 'Starting periodic 3-day full sync...');
      try {
        await syncFromSupabase(forceFullResync: true);
        await syncKannadaFromSupabase(forceFullResync: true);
        await syncOtherFromSupabase(forceFullResync: true);
        await prefs.setInt(lastFullSyncKey, nowMillis);
        AppLogger.d('LocalDB', 'Periodic full sync completed.');
      } catch (e) {
        AppLogger.e('LocalDB', 'Periodic full sync failed', e);
      }
    } else {
      AppLogger.d('LocalDB', 'Periodic sync not needed yet.');
    }
  }

  /// Triggers a background sync for a specific category (called when favoriting a new song).
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
