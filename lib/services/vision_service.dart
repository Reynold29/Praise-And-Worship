import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VisionService {
  static Future<String> extractTextFromImage(File image, String apiKey) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['responses'][0]['fullTextAnnotation']?['text'] ?? '';
      return text;
    } else {
      throw Exception('Vision API error: [31m${response.body}[0m');
    }
  }
} 