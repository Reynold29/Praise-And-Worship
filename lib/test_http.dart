import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('--- Starting Raw HTTP JSON Fetch ---');
  await dotenv.load(fileName: ".env");
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;

  final response = await http.get(
    Uri.parse('$url/rest/v1/english_data?select=*'),
    headers: {
      'apikey': key,
      'Authorization': 'Bearer $key',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    print('Fetched ${data.length} english_data rows.');

    int broken = 0;
    for (int i = 0; i < data.length; i++) {
      final row = data[i] as Map<String, dynamic>;

      // Manual schema check
      if (row['title'] == null) {
        print('Row $i is missing title! ID: ${row['id']}');
        broken++;
      }
      if (row['lyrics'] == null) {
        print('Row $i is missing lyrics! ID: ${row['id']}');
        broken++;
      }
      if (row['category'] == null) {
        print('Row $i is missing category! ID: ${row['id']}');
        broken++;
      }
    }

    print('Found $broken broken rows total.');
    if (data.isNotEmpty && broken == 0) {
      print('Sample 0: ${data[0]['title']}');
    }
  } else {
    print('Failed with status: ${response.statusCode}');
    print(response.body);
  }
}
