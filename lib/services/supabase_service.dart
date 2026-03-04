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
      final response = await _client
          .from(categoryKey)
          .select()
          .order('title', ascending: true);

      if (response == null) {
        AppLogger.w('SupabaseService', 'Query returned null for $categoryKey');
        return [];
      }
      final List<dynamic> responseData = response as List<dynamic>;
      final songs = responseData.map((data) {
        final parsed = Song.fromJson(data as Map<String, dynamic>,
            categoryOverride: categoryKey == 'other_data' ? null : categoryKey);
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

  // You can add more methods here for other Supabase interactions:
  // - getSongById(String id)
  // - addSong(Song song)
  // - updateSong(Song song)
  // - deleteSong(String id)
}
