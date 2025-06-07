import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteProvider with ChangeNotifier {
  List<String> _favoriteSongKeys = [];

  List<String> get favoriteSongKeys => _favoriteSongKeys;

  FavoriteProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteSongKeys = prefs.getStringList('favorite_songs') ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String category, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$category|$id';

    if (_favoriteSongKeys.contains(key)) {
      _favoriteSongKeys.remove(key);
      print('[FavoriteProvider] Removed favorite key: $key');
    } else {
      _favoriteSongKeys.add(key);
      print('[FavoriteProvider] Added favorite key: $key');
    }
    await prefs.setStringList('favorite_songs', _favoriteSongKeys);
    notifyListeners();
  }

  bool isFavorite(String category, String id) {
    return _favoriteSongKeys.contains('$category|$id');
  }

  // Method to re-sync favorites from SharedPreferences (e.g., after initial load or manual changes)
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }
} 