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
          .from('english_data')
          .select()
          .order('title', ascending: true);

      if (response == null) {
        print('Supabase query returned null (fetching all songs from english_data)');
        return [];
      }
      final List<dynamic> responseData = response as List<dynamic>; 
      final songs = responseData.map((data) => Song.fromJson(data as Map<String, dynamic>)).toList();
      return songs;
    } catch (e) {
      print('Error fetching all songs from english_data: $e');
      throw Exception('Failed to load songs: $e');
    }
  }

  Future<bool> submitSongForReview(Map<String, dynamic> songData) async {
    try {
      await _client.from('pending_songs').insert(songData);
      // If no exception, treat as success
      return true;
    } on PostgrestException catch (e) {
      print('Supabase insert error: \\${e.message}');
      throw Exception('Failed to submit song: \\${e.message}');
    } catch (e) {
      print('Error submitting song for review: \\${e.toString()}');
      rethrow;
    }
  }

  // You can add more methods here for other Supabase interactions:
  // - getSongById(String id)
  // - addSong(Song song)
  // - updateSong(Song song)
  // - deleteSong(String id)
} 