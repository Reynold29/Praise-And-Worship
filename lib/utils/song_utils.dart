class SongUtils {
  /// Converts a song's lyrics and chords into the line-by-line format expected
  /// by SongDetailScreen. Replacing duplicated _convertSongToLines everywhere.
  static List<Map<String, dynamic>> parseLyricsToLines(
      String lyrics, String? chords) {
    if (lyrics.isEmpty) return [];

    final lyricLines = lyrics.split('\n');
    final chordLines = (chords ?? '').split('\n');
    final lines = <Map<String, dynamic>>[];

    for (int i = 0; i < lyricLines.length; i++) {
      // Add chords line if present and not empty
      if (i < chordLines.length && chordLines[i].trim().isNotEmpty) {
        lines
            .add({'type': 'chords', 'chords': _parseChordsLine(chordLines[i])});
      }
      // Add lyric line
      lines.add({'type': 'lyric', 'lyric': lyricLines[i]});
    }

    // Capture trailing chord lines (e.g. tag at the end without lyrics underneath)
    for (int i = lyricLines.length; i < chordLines.length; i++) {
      if (chordLines[i].trim().isNotEmpty) {
        lines
            .add({'type': 'chords', 'chords': _parseChordsLine(chordLines[i])});
      }
    }

    return lines;
  }

  static String languageLabel(String category) {
    final c = category.trim().toLowerCase();
    if (c.contains('kannada')) return 'Kannada';
    if (c.contains('english')) return 'English';
    return 'Other';
  }

  static String chipLabel(String category, String? genre) {
    final g = genre?.trim();
    if (g != null && g.isNotEmpty) return g;
    return languageLabel(category);
  }

  /// Helper to parse a chord line into a list of chords with pre_spaces
  static List<Map<String, dynamic>> _parseChordsLine(String chordLine) {
    final chords = <Map<String, dynamic>>[];
    final regex = RegExp(r'\S+');
    for (final match in regex.allMatches(chordLine)) {
      chords.add({
        'note': match.group(0),
        'pre_spaces': match.start,
      });
    }
    return chords;
  }
}
