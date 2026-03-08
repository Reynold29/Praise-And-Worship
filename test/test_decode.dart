import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worshipcompanion/models/song_model.dart';

void main() {
  test('Test Supabase Sync and Decode', () async {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    print('Testing english_data fetch:');
    final response = await Supabase.instance.client
        .from('english_data')
        .select()
        .order('title', ascending: true);
    final List<dynamic> responseData = response as List<dynamic>;
    print('english_data count: ${responseData.length}');

    final List<Map<String, dynamic>> jsonList = [];
    int successCount = 0;

    for (int i = 0; i < responseData.length; i++) {
      try {
        final map = responseData[i] as Map<String, dynamic>;
        final song = Song.fromJson(map, categoryOverride: 'english_data');
        jsonList.add(song.toJson());
        successCount++;
      } catch (e) {
        print(
            'FAILED to parse entry at index $i: $e. Data: ${responseData[i]}');
      }
    }

    print(
        'Successfully parsed $successCount out of ${responseData.length} english_data songs.');

    // Test JSON file cycle simulating LocalDatabaseService
    final jsonString = jsonEncode(jsonList);
    final decoded = jsonDecode(jsonString) as List<dynamic>;

    int decodeSuccess = 0;
    for (int i = 0; i < decoded.length; i++) {
      try {
        Song.fromJson(decoded[i] as Map<String, dynamic>);
        decodeSuccess++;
      } catch (e) {
        print('FAILED jsonDecode at index $i: $e');
      }
    }

    print(
        'Successfully cycled $decodeSuccess english_data songs to/from JSON String.');
  });
}
