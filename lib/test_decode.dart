import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/supabase_service.dart';

void main() async {
  print('--- Starting Raw Supabase Fetch Debug ---');

  try {
    print('Testing english_data fetch:');
    final Map<String, dynamic> rawResponse = {};
    // This is just a script to check Supabase raw return types
    final List<Song> original =
        await SupabaseService.instance.getSongsByCategory('english_data');
    print('english_data count: ${original.length}');

    // Test serialization cycle
    try {
      final jsonString = jsonEncode(original.map((s) => s.toJson()).toList());
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      for (int i = 0; i < decoded.length; i++) {
        try {
          Song.fromJson(decoded[i] as Map<String, dynamic>);
        } catch (e) {
          print('FAILED to parse Song at index $i: $e. Data: ${decoded[i]}');
        }
      }
      print('Serialization cycle passed.');
    } catch (e) {
      print('Serialization failed: $e');
    }
  } catch (e) {
    print('Fatal error fetching english_data: $e');
  }
}
