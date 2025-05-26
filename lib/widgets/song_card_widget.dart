import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart'; // Import the detail screen

class SongCardWidget extends StatelessWidget {
  final Song song;

  const SongCardWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1.5, // Slightly reduced elevation
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // Reduced vertical margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Slightly smaller radius
      ),
      color: colorScheme.surfaceVariant.withAlpha(180), // Slightly more opaque
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongDetailScreen(tabData: {'title': song.title, 'artist_name': song.authorName ?? '', 'author': song.authorName ?? '', 'key_signature': song.keySignature, 'lines': _convertSongToLines(song)}),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Reduced vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important to keep card compact
            children: [
              Text(
                song.title,
                style: textTheme.titleMedium?.copyWith( // Changed from titleLarge to titleMedium
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600, // Kept fontWeight for emphasis
                ),
                maxLines: 1, // Reduced maxLines for title to make it more compact
                overflow: TextOverflow.ellipsis,
              ),
              if (song.authorName != null && song.authorName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3.0), // Reduced top padding
                  child: Text(
                    song.authorName!,
                    style: textTheme.bodySmall?.copyWith( // Changed from bodyMedium to bodySmall
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _convertSongToLines(Song song) {
    final lyricLines = song.lyrics.split('\n');
    final chordLines = (song.chords ?? '').split('\n');
    final lines = <Map<String, dynamic>>[];

    for (int i = 0; i < lyricLines.length; i++) {
      // Add chords line if present and not empty
      if (i < chordLines.length && chordLines[i].trim().isNotEmpty) {
        lines.add({'type': 'chords', 'chords': _parseChordsLine(chordLines[i])});
      }
      // Add lyric line
      lines.add({'type': 'lyric', 'lyric': lyricLines[i]});
    }
    return lines;
  }

  // Helper to parse a chord line into a list of chords with pre_spaces
  List<Map<String, dynamic>> _parseChordsLine(String chordLine) {
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