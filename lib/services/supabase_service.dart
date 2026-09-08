import '../utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worshipcompanion/models/song_model.dart';

class SupabaseService {
  // Private constructor for singleton pattern
  SupabaseService._privateConstructor();
  static final SupabaseService instance = SupabaseService._privateConstructor();

  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Song>> getSongsByCategory(String categoryKey) async {
    try {
      final response = await _client.from(categoryKey).select();

      final List<dynamic> responseData = response as List<dynamic>;
      AppLogger.w('SupabaseService',
          'Raw HTTP response length for $categoryKey: ${responseData.length}');

      // Derive a sensible category override per table so that missing/empty
      // category fields in Supabase rows do NOT become 'unknown_data'.
      String? override;
      switch (categoryKey) {
        case 'english_data':
          override = 'english';
          break;
        case 'kannada_data':
          override = 'kannada';
          break;
        case 'other_data':
          // Let each row's own 'category' tell us its language; if that is
          // missing, Song.fromJson will fall back to 'unknown_data'.
          override = null;
          break;
        default:
          override = null;
      }

      final songs = responseData.map((data) {
        final parsed = Song.fromJson(
          data as Map<String, dynamic>,
          categoryOverride: override,
        );
        return parsed;
      }).toList();
      return songs;
    } catch (e) {
      AppLogger.d('App', 'Error fetching all songs from english_data: $e');
      throw Exception('Failed to load songs: $e');
    }
  }

  Future<bool> submitSongForReview(Map<String, dynamic> songData) async {
    try {
      await _client.from('pending_songs').insert(songData);
      // If no exception, treat as success
      return true;
    } on PostgrestException catch (e) {
      AppLogger.d('App', 'Supabase insert error: \\${e.message}');
      throw Exception('Failed to submit song: \\${e.message}');
    } catch (e) {
      AppLogger.d('App', 'Error submitting song for review: \\${e.toString()}');
      rethrow;
    }
  }

  Future<bool> addSongDirect(
      String table, Map<String, dynamic> songData) async {
    try {
      await _client.from(table).insert(songData);
      return true;
    } on PostgrestException catch (e) {
      AppLogger.d('App', 'Supabase direct insert error: \\${e.message}');
      throw Exception('Failed to add song directly: \\${e.message}');
    } catch (e) {
      AppLogger.d('App', 'Error adding song directly: \\${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteSong(String table, String id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      AppLogger.d('App', 'Error deleting song from $table: \\${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateSong(
      String table, String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null && key != 'trans_lyrics');
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from(table).update(payload).eq('id', id);
    } on PostgrestException catch (e) {
      AppLogger.e('SupabaseService', 'updateSong failed: ${e.message}', e);
      throw Exception('Failed to update song: ${e.message}');
    } catch (e) {
      AppLogger.e('SupabaseService', 'updateSong failed', e);
      rethrow;
    }
  }

  /// Pending submissions awaiting master approval.
  Future<List<Map<String, dynamic>>> fetchPendingSongs() async {
    final response = await _client
        .from('pending_songs')
        .select()
        .or('is_reviewed.is.null,is_reviewed.eq.false')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Approves via is_reviewed trigger → inserts into language table.
  Future<void> approvePendingSong(String id) async {
    await _client.from('pending_songs').update({
      'is_reviewed': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> rejectPendingSong(String id) async {
    await _client.from('pending_songs').delete().eq('id', id);
  }

  /// Correct lyrics / metadata on a pending submission before approve.
  Future<void> updatePendingSong(
      String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..remove('id')
      ..removeWhere((key, value) => value == null && key != 'trans_lyrics');
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _client.from('pending_songs').update(payload).eq('id', id);
  }
}
