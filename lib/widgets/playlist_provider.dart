import 'dart:convert';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist_model.dart';
import '../services/playlists_sync_service.dart';
import '../utils/app_logger.dart';

class PlaylistProvider with ChangeNotifier {
  List<Playlist> _playlists = [];
  Map<String, List<PlaylistSong>> _playlistSongs =
      {}; // playlistId -> List of songs
  bool _isLoggedIn = false;
  bool _loading = false;

  List<Playlist> get playlists => _playlists.where((p) => !p.deleted).toList();
  bool get isLoading => _loading;
  bool get isLoggedIn => _isLoggedIn;

  PlaylistProvider() {
    loadLocal();
  }

  Future<void> switchToLocal() async {
    _isLoggedIn = false;
    await loadLocal();
  }

  Future<void> switchToCloud(String userId) async {
    final wasGuest = !_isLoggedIn;
    _isLoggedIn = true;
    if (wasGuest) {
      await _mergeLocalToCloud();
    }
    await loadCloud();
  }

  Future<void> loadLocal() async {
    _loading = true;
    notifyListeners();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pFile = File('${dir.path}/local_playlists.json');
      final sFile = File('${dir.path}/local_playlist_songs.json');

      if (await pFile.exists()) {
        final content = await pFile.readAsString();
        final List<dynamic> json = jsonDecode(content);
        _playlists = json.map((j) => Playlist.fromJson(j)).toList();
      } else {
        _playlists = [];
      }

      if (await sFile.exists()) {
        final content = await sFile.readAsString();
        final List<dynamic> json = jsonDecode(content);
        final songs = json.map((j) => PlaylistSong.fromJson(j)).toList();
        _playlistSongs = {};
        for (var s in songs) {
          _playlistSongs.putIfAbsent(s.playlistId, () => []).add(s);
        }
      } else {
        _playlistSongs = {};
      }
    } catch (e) {
      AppLogger.e('PlaylistProvider', 'loadLocal error', e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCloud() async {
    _loading = true;
    notifyListeners();
    try {
      final cloudPlaylists =
          await PlaylistsSyncService.instance.fetchCloudPlaylists();
      _playlists = cloudPlaylists;

      _playlistSongs = {};
      for (var p in _playlists) {
        final songs =
            await PlaylistsSyncService.instance.fetchPlaylistSongs(p.id);
        _playlistSongs[p.id] = songs;
      }
    } catch (e) {
      AppLogger.e('PlaylistProvider', 'loadCloud error', e);
      await loadLocal();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    if (!_isLoggedIn && playlists.length >= 3) {
      throw Exception('LIMIT_REACHED');
    }

    if (_isLoggedIn) {
      final newPlaylist =
          await PlaylistsSyncService.instance.createCloudPlaylist(name);
      _playlists.insert(0, newPlaylist);
      _playlistSongs[newPlaylist.id] = [];
    } else {
      final newPlaylist = Playlist(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
      );
      _playlists.insert(0, newPlaylist);
      _playlistSongs[newPlaylist.id] = [];
      await _persistLocal();
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (_isLoggedIn) {
      await PlaylistsSyncService.instance.deleteCloudPlaylist(playlistId);
      // Soft delete in memory
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = _playlists[index].copyWith(deleted: true);
      }
    } else {
      _playlists.removeWhere((p) => p.id == playlistId);
      _playlistSongs.remove(playlistId);
      await _persistLocal();
    }
    notifyListeners();
  }

  Future<void> addSongToPlaylist(
      String playlistId, String songId, String category) async {
    if (_isLoggedIn) {
      final ps = await PlaylistsSyncService.instance
          .addSongToCloudPlaylist(playlistId, songId, category);
      _playlistSongs.putIfAbsent(playlistId, () => []).add(ps);
    } else {
      final ps = PlaylistSong(
        id: const Uuid().v4(),
        playlistId: playlistId,
        songId: songId,
        category: category.replaceAll('_data', ''),
        addedAt: DateTime.now(),
      );
      _playlistSongs.putIfAbsent(playlistId, () => []).add(ps);
      await _persistLocal();
    }
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String playlistSongId) async {
    if (_isLoggedIn) {
      await PlaylistsSyncService.instance
          .removeSongFromCloudPlaylist(playlistSongId);
      _playlistSongs[playlistId]?.removeWhere((s) => s.id == playlistSongId);
    } else {
      _playlistSongs[playlistId]?.removeWhere((s) => s.id == playlistSongId);
      await _persistLocal();
    }
    notifyListeners();
  }

  Future<Playlist> importPlaylist(String name, List<PlaylistSong> songs) async {
    _loading = true;
    notifyListeners();

    try {
      // 1. Create a new playlist
      Playlist? newPlaylist;
      if (_isLoggedIn) {
        newPlaylist =
            await PlaylistsSyncService.instance.createCloudPlaylist(name);
      } else {
        if (playlists.length >= 3) {
          throw Exception('LIMIT_REACHED');
        }
        newPlaylist = Playlist(
          id: const Uuid().v4(),
          name: name,
          createdAt: DateTime.now(),
        );
      }

      // 2. Add songs in batch
      if (_isLoggedIn) {
        final importedSongs = await PlaylistsSyncService.instance
            .addSongsToCloudPlaylist(newPlaylist.id, songs);
        _playlists.insert(0, newPlaylist);
        _playlistSongs[newPlaylist.id] = importedSongs;
      } else {
        final importedSongs = songs
            .map((s) => s.copyWith(
                  id: const Uuid().v4(),
                  playlistId: newPlaylist!.id,
                  addedAt: DateTime.now(),
                ))
            .toList();
        _playlists.insert(0, newPlaylist);
        _playlistSongs[newPlaylist.id] = importedSongs;
        await _persistLocal();
      }

      _loading = false;
      notifyListeners();
      return newPlaylist;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  List<PlaylistSong> getSongsInPlaylist(String playlistId) {
    return _playlistSongs[playlistId] ?? [];
  }

  bool isSongInPlaylist(String playlistId, String songId) {
    return getSongsInPlaylist(playlistId).any((s) => s.songId == songId);
  }

  Future<void> _mergeLocalToCloud() async {
    try {
      // 1. Load local data if not already loaded
      if (_playlists.isEmpty) await loadLocal();
      if (_playlists.isEmpty) return;

      AppLogger.d('PlaylistProvider',
          'Merging ${_playlists.length} local playlists to cloud');

      for (var localP in _playlists) {
        // Create the playlist in cloud
        final cloudP = await PlaylistsSyncService.instance
            .createCloudPlaylist(localP.name);

        // Add all songs from this local playlist to the new cloud playlist
        final localSongs = _playlistSongs[localP.id] ?? [];
        for (var ls in localSongs) {
          await PlaylistsSyncService.instance
              .addSongToCloudPlaylist(cloudP.id, ls.songId, ls.category);
        }
      }

      // 2. Clear local data files after successful merge
      final dir = await getApplicationDocumentsDirectory();
      final pFile = File('${dir.path}/local_playlists.json');
      final sFile = File('${dir.path}/local_playlist_songs.json');
      if (await pFile.exists()) await pFile.delete();
      if (await sFile.exists()) await sFile.delete();

      _playlists = [];
      _playlistSongs = {};
    } catch (e) {
      AppLogger.e('PlaylistProvider', 'Merge error', e);
    }
  }

  Future<void> _persistLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pFile = File('${dir.path}/local_playlists.json');
      final sFile = File('${dir.path}/local_playlist_songs.json');

      await pFile.writeAsString(
          jsonEncode(_playlists.map((p) => p.toJson()).toList()));

      final allSongs = _playlistSongs.values.expand((list) => list).toList();
      await sFile
          .writeAsString(jsonEncode(allSongs.map((s) => s.toJson()).toList()));
    } catch (e) {
      AppLogger.e('PlaylistProvider', '_persistLocal error', e);
    }
  }
}
