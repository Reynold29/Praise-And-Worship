import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist_model.dart';

class PlaylistsSyncService {
  PlaylistsSyncService._();
  static final PlaylistsSyncService instance = PlaylistsSyncService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Playlist>> fetchCloudPlaylists() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _client
        .from('playlists')
        .select()
        .eq('user_id', uid)
        .eq('deleted', false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Playlist.fromJson(json)).toList();
  }

  Future<List<PlaylistSong>> fetchPlaylistSongs(String playlistId) async {
    final response = await _client
        .from('playlist_songs')
        .select()
        .eq('playlist_id', playlistId);

    return (response as List)
        .map((json) => PlaylistSong.fromJson(json))
        .toList();
  }

  Future<Playlist> createCloudPlaylist(String name) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not logged in');

    final response = await _client
        .from('playlists')
        .insert({
          'user_id': uid,
          'name': name,
        })
        .select()
        .single();

    return Playlist.fromJson(response);
  }

  Future<void> deleteCloudPlaylist(String playlistId) async {
    // Soft delete as per requirement
    await _client
        .from('playlists')
        .update({'deleted': true}).eq('id', playlistId);
  }

  Future<PlaylistSong> addSongToCloudPlaylist(
      String playlistId, String songId, String category) async {
    final response = await _client
        .from('playlist_songs')
        .insert({
          'playlist_id': playlistId,
          'song_id': songId,
          'category': category.replaceAll('_data', ''),
        })
        .select()
        .single();

    return PlaylistSong.fromJson(response);
  }

  Future<List<PlaylistSong>> addSongsToCloudPlaylist(
      String playlistId, List<PlaylistSong> songs) async {
    if (songs.isEmpty) return [];

    final data = songs.map((s) => {
      'playlist_id': playlistId,
      'song_id': s.songId,
      'category': s.category.replaceAll('_data', ''),
    }).toList();

    final response = await _client
        .from('playlist_songs')
        .insert(data)
        .select();

    return (response as List)
        .map((json) => PlaylistSong.fromJson(json))
        .toList();
  }

  Future<void> removeSongFromCloudPlaylist(String playlistSongId) async {
    await _client.from('playlist_songs').delete().eq('id', playlistSongId);
  }

  Future<Playlist?> fetchPlaylistById(String playlistId) async {
    final response = await _client
        .from('playlists')
        .select()
        .eq('id', playlistId)
        .eq('deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return Playlist.fromJson(response);
  }

  Future<List<PlaylistSong>> fetchPlaylistSongsById(String playlistId) async {
    final response = await _client
        .from('playlist_songs')
        .select()
        .eq('playlist_id', playlistId);

    return (response as List)
        .map((json) => PlaylistSong.fromJson(json))
        .toList();
  }
}
