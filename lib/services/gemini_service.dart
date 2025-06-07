import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static Future<Map<String, String>> parseSongText(String text, String apiKey, {bool addChords = false}) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
    final prompt = '''
Extract the full song title, author, and all lyrics from the following text.
Reply with the title on the first line, author on the second line, a blank line, then the full lyrics exactly as they appear, preserving all verses and choruses.
${addChords ? 'Add plausible chords above the lyrics in Ultimate Guitar style, using the key and genre if present.' : ''}
Do not summarize or omit any part of the lyrics.
Do not return JSON or any other structured format—just plain text as described.

$text
''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body);
    final candidates = data['candidates'];
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in Gemini response');
    }
    final content = candidates[0]['content'];
    if (content == null || content['parts'] == null || content['parts'].isEmpty) {
      throw Exception('No content parts in Gemini response');
    }
    final responseText = content['parts'][0]['text'];
    if (responseText == null || responseText is! String) {
      throw Exception('No text in Gemini response');
    }
    // Parse: title (1st line), author (2nd line), blank, then lyrics
    final lines = responseText.split('\n');
    final title = lines.isNotEmpty ? lines[0].trim() : '';
    final author = lines.length > 1 ? lines[1].trim() : '';
    int lyricsStart = 2;
    while (lyricsStart < lines.length && lines[lyricsStart].trim().isEmpty) {
      lyricsStart++;
    }
    final lyrics = lines.sublist(lyricsStart).join('\n').trim();
    return {'title': title, 'author': author, 'lyrics': lyrics};
  }
} 