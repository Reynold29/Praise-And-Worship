import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart'; // Import the detail screen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:vibration/vibration.dart';

class SongCardWidget extends StatefulWidget {
  final Song song;
  final double fontSize;
  final bool hideFavoriteButton;
  final bool showEnglishTitle;

  const SongCardWidget(
      {super.key,
      required this.song,
      this.fontSize = 16,
      this.hideFavoriteButton = false,
      this.showEnglishTitle = false});

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
    final bool isFavorite =
        favoriteProvider.isFavorite(widget.song.category, widget.song.id);

    // Determine if this is a Kannada song
    final isKannada =
        widget.song.category.trim().toLowerCase() == 'kannada_data' ||
            widget.song.category.trim().toLowerCase() == 'kannada';
    final hasAuthor = widget.song.authorName != null &&
        widget.song.authorName!.trim().isNotEmpty;

    return Card(
      elevation: 1.5, // Slightly reduced elevation
      margin: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 6.0), // Reduced vertical margin
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
                  'title': (widget.showEnglishTitle &&
                          widget.song.englishTitle != null &&
                          widget.song.englishTitle!.isNotEmpty)
                      ? widget.song.englishTitle!
                      : widget.song.title,
                  'original_title': widget.song.title,
                  'english_title': widget.song.englishTitle,
                  'artist_name': widget.song.authorName ?? '',
                  'author': widget.song.authorName ?? '',
                  'key_signature': widget.song.keySignature,
                  'youtube_link': widget.song.youtubeLink,
                  'lines': SongUtils.parseLyricsToLines(
                      widget.song.lyrics, widget.song.chords),
                  'trans_lines': widget.song.transLyrics != null &&
                          widget.song.transLyrics!.isNotEmpty
                      ? SongUtils.parseLyricsToLines(
                          widget.song.transLyrics!, widget.song.chords)
                      : null,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0), // Slightly less vertical padding
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
                      (widget.showEnglishTitle &&
                              widget.song.englishTitle != null &&
                              widget.song.englishTitle!.isNotEmpty)
                          ? widget.song.englishTitle!
                          : widget.song.title,
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
                          : (widget.song.authorName != null &&
                                  widget.song.authorName!.isNotEmpty
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
                  icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant),
                  tooltip:
                      isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  onPressed: () {
                    _performVibration();
                    favoriteProvider.toggleFavorite(
                        widget.song.category, widget.song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite
                            ? 'Removed from favorites'
                            : 'Added to favorites'),
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
}
