import 'dart:math'; // For random number generation

class VerseApi {
  Future<String> fetchVerseOfTheDay() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1)); 

    // Dummy verses
    final verses = [
      "For God so loved the world, that \nhe gave his only Son \n(John 3:16)",
    ];

    // Return a random verse
    return verses[Random().nextInt(verses.length)];
  }
}
