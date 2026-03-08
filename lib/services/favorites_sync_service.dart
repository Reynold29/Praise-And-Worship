import '../utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Handles all Supabase `user_favorites` table reads and writes.
/// All public methods are safe to call in non-UI contexts (isolate-free).
class FavoritesSyncService {
  FavoritesSyncService._();
  static final FavoritesSyncService instance = FavoritesSyncService._();

  static const _table = 'user_favorites';

  final SupabaseClient _client = Supabase.instance.client;

  // ── Connectivity guard ──────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    if (result.isEmpty) return true;
    return !(result.length == 1 && result.first == ConnectivityResult.none);
  }

  // ── Fetch ───────────────────────────────────────────────────────────────

  /// Returns the full set of song-keys saved in the cloud for [userId].
  Future<Set<String>> fetchCloudFavorites(String userId) async {
    try {
      if (!await _isOnline()) return {};
      final rows =
          await _client.from(_table).select('song_key').eq('user_id', userId);
      return {for (final r in rows as List) r['song_key'] as String};
    } catch (e) {
      AppLogger.d('FavSync', 'fetchCloudFavorites error: $e');
      return {};
    }
  }

  // ── Upsert single ───────────────────────────────────────────────────────

  /// Adds (or no-ops if already present) a single favourite for [userId].
  Future<void> addToCloud(String userId, String songKey) async {
    try {
      if (!await _isOnline()) return;
      await _client.from(_table).upsert(
        {'user_id': userId, 'song_key': songKey},
        onConflict: 'user_id,song_key',
      );
    } catch (e) {
      AppLogger.d('FavSync', 'addToCloud error ($songKey): $e');
    }
  }

  // ── Delete single ───────────────────────────────────────────────────────

  /// Removes a single favourite for [userId].
  Future<void> removeFromCloud(String userId, String songKey) async {
    try {
      if (!await _isOnline()) return;
      await _client
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('song_key', songKey);
    } catch (e) {
      AppLogger.d('FavSync', 'removeFromCloud error ($songKey): $e');
    }
  }

  // ── Batch upsert ────────────────────────────────────────────────────────

  /// Pushes [keys] to the cloud in one batch. Used during initial sync.
  Future<void> pushToCloud(String userId, Iterable<String> keys) async {
    final list = keys.toList();
    if (list.isEmpty) return;
    try {
      if (!await _isOnline()) return;
      final rows = list.map((k) => {'user_id': userId, 'song_key': k}).toList();
      await _client.from(_table).upsert(rows, onConflict: 'user_id,song_key');
      AppLogger.d('FavSync', 'pushToCloud: ${list.length} keys uploaded.');
    } catch (e) {
      AppLogger.d('FavSync', 'pushToCloud error: $e');
    }
  }

  // ── Merge local → cloud ────────────────────────────────────────────────

  /// Additive merge: uploads any [localKeys] that are not yet in the cloud.
  /// Never deletes cloud rows — safe first-time sync.
  Future<void> mergeLocalToCloud(
      String userId, Iterable<String> localKeys) async {
    try {
      if (!await _isOnline()) {
        AppLogger.d('FavSync', 'merge skipped — offline.');
        return;
      }
      final cloudKeys = await fetchCloudFavorites(userId);
      final toUpload =
          localKeys.where((k) => k.isNotEmpty && !cloudKeys.contains(k));
      await pushToCloud(userId, toUpload);
    } catch (e) {
      AppLogger.d('FavSync', 'mergeLocalToCloud error: $e');
    }
  }
}
