import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart'; // Import the detail screen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:vibration/vibration.dart';

class SongCardWidget extends StatefulWidget {
  final Song song;
  final double fontSize;
  final bool hideFavoriteButton;

  const SongCardWidget({super.key, required this.song, this.fontSize = 16, this.hideFavoriteButton = false});

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  @override
  void initState() {
    super.initState();
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final bool isFavorite = favoriteProvider.isFavorite(widget.song.category, widget.song.id);

    // Determine if this is a Kannada song
    final isKannada = widget.song.category.trim().toLowerCase() == 'kannada_data' || widget.song.category.trim().toLowerCase() == 'kannada';
    final hasAuthor = widget.song.authorName != null && widget.song.authorName!.trim().isNotEmpty;

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
              builder: (context) => SongDetailScreen(
                tabData: {
                  'id': widget.song.id,
                  'category': widget.song.category,
                  'title': widget.song.title,
                  'artist_name': widget.song.authorName ?? '',
                  'author': widget.song.authorName ?? '',
                  'key_signature': widget.song.keySignature,
                  'lines': _convertSongToLines(widget.song)
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Slightly less vertical padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.song.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.fontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      isKannada
                        ? (hasAuthor ? widget.song.authorName! : '—')
                        : (widget.song.authorName != null && widget.song.authorName!.isNotEmpty
                            ? widget.song.authorName!
                            : ''),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: widget.fontSize - 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!widget.hideFavoriteButton)
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant),
                  tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  onPressed: () {
                    _performVibration();
                    print('[_SongCardWidgetState] Toggling favorite for song: ${widget.song.title}, Category: ${widget.song.category}, ID: ${widget.song.id}');
                    favoriteProvider.toggleFavorite(widget.song.category, widget.song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
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