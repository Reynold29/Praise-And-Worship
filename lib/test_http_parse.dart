import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:worshipcompanion/models/song_model.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;

  Future<void> testTable(String table) async {
    final response = await http.get(
      Uri.parse('$url/rest/v1/$table?select=*'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('[$table] HTTP fetched ${data.length} rows.');

      int parsedCount = 0;
      for (int i = 0; i < data.length; i++) {
        try {
          Song.fromJson(data[i] as Map<String, dynamic>);
          parsedCount++;
        } catch (e) {
          print('[$table] Error parsing row $i: $e');
          break; // Stop on first error to avoid spam
        }
      }
      print(
          '[$table] Successfully parsed $parsedCount rows via Song.fromJson.');
    } else {
      print('[$table] HTTP failed with status: ${response.statusCode}');
    }
  }

  await testTable('other_data');
  await testTable('english_data');
  await testTable('kannada_data');
}
