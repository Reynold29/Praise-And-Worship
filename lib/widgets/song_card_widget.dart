import 'package:material_ui/material_ui.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:flutter/services.dart';

class SongCardWidget extends StatefulWidget {
  final Song song;
  final int? displayIndex;
  final double fontSize;
  final bool hideFavoriteButton;
  final bool showEnglishTitle;

  const SongCardWidget(
      {super.key,
      required this.song,
      this.displayIndex,
      this.fontSize = 16,
      this.hideFavoriteButton = false,
      this.showEnglishTitle = false});

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  void _performVibration() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final bool isFavorite =
        favoriteProvider.isFavorite(widget.song.category, widget.song.id);

    final isKannada =
        widget.song.category.trim().toLowerCase() == 'kannada_data' ||
            widget.song.category.trim().toLowerCase() == 'kannada';
    final hasAuthor = widget.song.authorName != null &&
        widget.song.authorName!.trim().isNotEmpty;

    final baseTitle = (widget.showEnglishTitle &&
            widget.song.englishTitle != null &&
            widget.song.englishTitle!.isNotEmpty)
        ? widget.song.englishTitle!
        : widget.song.title;

    final displayTitle = widget.displayIndex != null
        ? '${widget.displayIndex}. $baseTitle'
        : baseTitle;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: colorScheme.surfaceContainerHighest.withAlpha(180),
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
                  'title': baseTitle,
                  'original_title': widget.song.title,
                  'english_title': widget.song.englishTitle,
                  'artist_name': widget.song.authorName ?? '',
                  'author': widget.song.authorName ?? '',
                  'key_signature': widget.song.keySignature,
                  'youtube_link': widget.song.youtubeLink,
                  'genre': widget.song.genre,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.fontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isKannada
                          ? (hasAuthor ? widget.song.authorName! : '—')
                          : (widget.song.authorName != null &&
                                  widget.song.authorName!.isNotEmpty
                              ? widget.song.authorName!
                              : ''),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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

/// Compact identity header used on the lyrics screen card only.
class SongIdentityBlock extends StatelessWidget {
  const SongIdentityBlock({
    super.key,
    required this.indexLabel,
    required this.chipLabel,
    required this.title,
    this.titleSize = 17,
    this.keyLabel,
    this.authorLabel,
  });

  final String indexLabel;
  final String chipLabel;
  final String title;
  final double titleSize;
  final String? keyLabel;
  final String? authorLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metaColor = colorScheme.onSurfaceVariant;
    final metaStyle = textTheme.bodySmall?.copyWith(
      color: metaColor,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                indexLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: metaColor,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                chipLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: titleSize,
            height: 1.15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (keyLabel != null || authorLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (keyLabel != null) ...[
                Text('🎹', style: metaStyle?.copyWith(fontSize: 13)),
                const SizedBox(width: 4),
                Flexible(
                  flex: 0,
                  child: Text(
                    keyLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                ),
              ],
              if (keyLabel != null && authorLabel != null)
                const SizedBox(width: 12),
              if (authorLabel != null)
                Expanded(
                  child: Row(
                    children: [
                      Text('👤', style: metaStyle?.copyWith(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('Singer: ', style: metaStyle),
                      Expanded(
                        child: _MarqueeName(
                          text: authorLabel!,
                          style: metaStyle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MarqueeName extends StatefulWidget {
  const _MarqueeName({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_MarqueeName> createState() => _MarqueeNameState();
}

class _MarqueeNameState extends State<_MarqueeName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didUpdateWidget(covariant _MarqueeName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller
        ..reset()
        ..stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final extra = painter.width - constraints.maxWidth;
        painter.dispose();

        if (extra <= 0) {
          if (_controller.isAnimating || _controller.value != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.stop();
                _controller.value = 0;
              }
            });
          }
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: widget.style,
          );
        }

        if (!_controller.isAnimating) {
          _controller.duration = Duration(
            milliseconds: (2400 + extra * 18).round().clamp(2400, 8000),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_controller.isAnimating) {
              _controller.repeat(reverse: true);
            }
          });
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Transform.translate(
                offset: Offset(-extra * t, 0),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                widget.text,
                maxLines: 1,
                softWrap: false,
                style: widget.style,
              ),
            ),
          ),
        );
      },
    );
  }
}
