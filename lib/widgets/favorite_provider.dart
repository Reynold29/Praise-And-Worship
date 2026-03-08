import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favorites_sync_service.dart';
import '../utils/app_logger.dart';

/// Dual-mode favourite store.
///
/// • **Local mode** (user not logged in): reads/writes SharedPreferences only.
/// • **Cloud mode** (user logged in):     reads from Supabase on first load,
///   then keeps SharedPreferences as a fast local mirror and fire-and-forgets
///   cloud writes so the UI is never blocked.
///
/// In-memory [Set<String>] is the single source of truth during a session,
/// eliminating repeated list-scans on every rebuild.
class FavoriteProvider with ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  final Set<String> _cache = {};
  bool _isLoggedIn = false;
  String? _userId;
  bool _loading = false;

  // ── Public API ────────────────────────────────────────────────────────────

  List<String> get favoriteSongKeys => _cache.toList();
  bool get isLoading => _loading;
  bool get isLoggedIn => _isLoggedIn;

  FavoriteProvider() {
    _loadLocal();
  }

  /// Switches to **local mode** — loads favourites from SharedPreferences only.
  Future<void> switchToLocal() async {
    _isLoggedIn = false;
    _userId = null;
    await _loadLocal();
  }

  /// Switches to **cloud mode** — loads favourites from Supabase and mirrors
  /// them into SharedPreferences so the next cold start is instant even if
  /// there's no internet.
  Future<void> switchToCloud(String userId) async {
    _isLoggedIn = true;
    _userId = userId;
    await _loadCloud(userId);
  }

  /// Toggles a favourite and persists to both local storage and (if logged in)
  /// Supabase. The cloud write is fire-and-forget to keep the UI snappy.
  Future<void> toggleFavorite(String category, String id) async {
    final normalizedCategory = category.replaceAll('_data', '');
    final cleanKey = '$normalizedCategory|$id';
    final legacyKey = '${normalizedCategory}_data|$id';

    bool removed = false;

    if (_cache.contains(cleanKey)) {
      _cache.remove(cleanKey);
      AppLogger.d('FavProvider', 'Removed clean key: $cleanKey');
      if (_isLoggedIn && _userId != null) {
        unawaited(
            FavoritesSyncService.instance.removeFromCloud(_userId!, cleanKey));
      }
      removed = true;
    }

    if (_cache.contains(legacyKey)) {
      _cache.remove(legacyKey);
      AppLogger.d('FavProvider', 'Removed legacy key: $legacyKey');
      if (_isLoggedIn && _userId != null) {
        unawaited(
            FavoritesSyncService.instance.removeFromCloud(_userId!, legacyKey));
      }
      removed = true;
    }

    // If it wasn't found in either format, it means the user is adding it
    if (!removed) {
      _cache.add(cleanKey); // Always store cleanly moving forward
      AppLogger.d('FavProvider', 'Added: $cleanKey');
      if (_isLoggedIn && _userId != null) {
        unawaited(FavoritesSyncService.instance.addToCloud(_userId!, cleanKey));
      }
    }

    unawaited(_persistLocal());
    notifyListeners();
  }

  bool isFavorite(String category, String id) {
    final normalizedCategory = category.replaceAll('_data', '');
    return _cache.contains('$normalizedCategory|$id') ||
        _cache.contains('${normalizedCategory}_data|$id');
  }

  /// Re-loads from shared prefs (used by connectivity listener in main.dart).
  Future<void> refreshFavorites() async {
    if (_isLoggedIn && _userId != null) {
      await _loadCloud(_userId!);
    } else {
      await _loadLocal();
    }
  }

  /// Bulk-adds keys (used after "Sync Now" in the sync dialog).
  Future<void> addBulkFromCloud(Iterable<String> keys) async {
    _cache.addAll(keys);
    await _persistLocal();
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('favorite_songs') ?? [];
      _cache
        ..clear()
        ..addAll(stored);
    } catch (e) {
      AppLogger.e('FavProvider', '_loadLocal error', e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCloud(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final cloudKeys =
          await FavoritesSyncService.instance.fetchCloudFavorites(userId);
      if (cloudKeys.isNotEmpty) {
        _cache
          ..clear()
          ..addAll(cloudKeys);
        // Mirror cloud state to local so next launch is fast
        await _persistLocal();
      } else {
        // Cloud empty — fall back to local (first-time login before merge)
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getStringList('favorite_songs') ?? [];
        _cache
          ..clear()
          ..addAll(stored);
      }
    } catch (e) {
      AppLogger.e('FavProvider', '_loadCloud error', e);
      await _loadLocal();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_songs', _cache.toList());
    } catch (e) {
      AppLogger.e('FavProvider', '_persistLocal error', e);
    }
  }
}

void unawaited(Future<void> future) {
  future.catchError(
      (Object e) => AppLogger.e('FavProvider', 'fire-and-forget error', e));
}
