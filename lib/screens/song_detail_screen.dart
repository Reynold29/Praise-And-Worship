import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class SongDetailScreen extends StatefulWidget {
  final Map<String, dynamic>
      tabData; // expects the parsed 'tab' object from your API

  const SongDetailScreen({super.key, required this.tabData});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  bool _showChords = false;
  int _transposeSemitones = 0;
  String? _originalKeyFromDB;
  String? _derivedKeyFromChords;
  double _fontSize = 16;
  bool _showTransliteration = false;
  bool _showEnglishTitle = true;

  // YouTube inline player state
  YoutubePlayerController? _ytController;
  bool _showYoutubePlayer = false;

  List<dynamic> get _lines {
    if (_showTransliteration && widget.tabData['trans_lines'] != null) {
      return widget.tabData['trans_lines'] as List<dynamic>;
    }
    return widget.tabData['lines'] as List<dynamic>;
  }

  String get _title {
    if (_showEnglishTitle &&
        widget.tabData['english_title'] != null &&
        widget.tabData['english_title'].toString().isNotEmpty) {
      return widget.tabData['english_title'] as String;
    }
    return widget.tabData['original_title'] ??
        widget.tabData['title'] ??
        'Untitled';
  }

  String get _artistName =>
      widget.tabData['artist_name'] ?? ''; // Used for "Author: ..."
  String get _authorForCopyright =>
      widget.tabData['author'] ?? ''; // Used for copyright

  String? get _youtubeLink => widget.tabData['youtube_link'] as String?;

  String? get _youtubeVideoId {
    if (_youtubeLink == null || _youtubeLink!.isEmpty) return null;
    return YoutubePlayerController.convertUrlToId(_youtubeLink!);
  }

  static const double _kControlsButtonHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _originalKeyFromDB = widget.tabData['key_signature'] as String?;
    if (_originalKeyFromDB == null || _originalKeyFromDB!.isEmpty) {
      _derivedKeyFromChords = _findOriginalKeyFromChords();
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  void _closeYoutubePlayer() {
    _ytController?.close();
    setState(() {
      _ytController = null;
      _showYoutubePlayer = false;
    });
  }

  String? _findOriginalKeyFromChords() {
    for (final line in _lines) {
      if (line is Map && line['type'] == 'chords') {
        final chordsList = line['chords'] as List<dynamic>?;
        if (chordsList != null && chordsList.isNotEmpty) {
          final firstChordData = chordsList.first as Map<String, dynamic>?;
          if (firstChordData != null) {
            final note = firstChordData['note'] as String?;
            if (note != null && note.isNotEmpty) {
              final RegExp chordRegex = RegExp(r'^([A-Ga-g][#b]?)');
              final match = chordRegex.firstMatch(note);
              if (match != null && match.group(1) != null) {
                return match.group(1)!.toUpperCase();
              }
              return note.toUpperCase();
            }
          }
        }
      }
    }
    return null;
  }

  String get displayKey {
    final keyToUse = _originalKeyFromDB?.isNotEmpty == true
        ? _originalKeyFromDB
        : _derivedKeyFromChords;
    if (keyToUse == null || keyToUse.isEmpty) return "N/A";
    return _transposeNote(keyToUse, _transposeSemitones);
  }

  String get originalDisplayKey {
    return _originalKeyFromDB?.isNotEmpty == true
        ? _originalKeyFromDB!
        : (_derivedKeyFromChords ?? "N/A");
  }

  String transposeChord(String chord, int semitones) {
    if (semitones == 0) return chord;
    return _transposeChordInternal(chord, semitones);
  }

  static const List<String> _notesSharp = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  static const List<String> _notesFlat = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B'
  ];

  String _transposeNote(String note, int semitones) {
    String noteUpper = note.toUpperCase();
    int noteIndex = _notesSharp.indexOf(noteUpper);
    if (noteIndex == -1) noteIndex = _notesFlat.indexOf(noteUpper);
    if (noteIndex == -1) return note;

    int transposedIndex = (noteIndex + semitones) % 12;
    if (transposedIndex < 0) transposedIndex += 12;
    return _notesSharp[transposedIndex];
  }

  String _transposeChordInternal(String chord, int semitones) {
    if (semitones == 0) return chord;
    final RegExp chordRegex =
        RegExp(r'^([A-Ga-g][#b]?)([^/]*)(?:/([A-Ga-g][#b]?))?');
    final match = chordRegex.firstMatch(chord);
    if (match == null) return chord;

    String root = match.group(1)!;
    String quality = match.group(2) ?? '';
    String? bassNote = match.group(3);

    String transposedRoot = _transposeNote(root, semitones);
    String? transposedBass =
        bassNote != null ? _transposeNote(bassNote, semitones) : null;

    return transposedRoot +
        quality +
        (transposedBass != null ? '/${_transposeNote(transposedBass, 0)}' : '');
  }

  void _performVibration() {
    HapticFeedback.lightImpact();
  }

  void _confirmDeleteSong(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Song?'),
          content: const Text(
              'This will permanently delete this song from the database. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                _performDeleteSong();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteSong() async {
    final String songId = widget.tabData['id'].toString();
    final String songCategory = widget.tabData['category'] as String;

    // Convert generic category to DB table names if necessary.
    // If getting songs is mapping table to category, map it back.
    String tableName = songCategory;
    if (!tableName.endsWith('_data')) {
      if (tableName == 'english')
        tableName = 'english_data';
      else if (tableName == 'kannada')
        tableName = 'kannada_data';
      else
        tableName = 'other_data';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SupabaseService.instance.deleteSong(tableName, songId);
      if (mounted) {
        Navigator.of(context).pop(); // remove loading indicator
        Navigator.of(context).pop(); // go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Only show transposition and chords controls if the song actually has chords
    final bool hasAnyChords = _lines.any((line) =>
        line is Map &&
        line['type'] == 'chords' &&
        (line['chords'] as List?)?.isNotEmpty == true);

    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    final String songId = widget.tabData['id'].toString();
    final String songCategory = widget.tabData['category'] as String;
    final bool isFavorite = favoriteProvider.isFavorite(songCategory, songId);

    final bool isMaster =
        appConfigProvider.isMasterUser(authProvider.currentUser?.email);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                // elasticOut overshoots past 1.0 naturally — that IS the bounce.
                // Never use TweenSequence here; it asserts t ∈ [0,1] and crashes.
                final scale =
                    Tween<double>(begin: 0.5, end: 1.0).animate(animation);
                return ScaleTransition(scale: scale, child: child);
              },
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: () {
              _performVibration();
              favoriteProvider.toggleFavorite(songCategory, songId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite
                      ? 'Removed from favorites'
                      : 'Added to favorites'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 20.0,
              // When the YouTube player is visible, add its height so lyrics
              // are scrollable past the overlay and fully accessible.
              bottom: _showYoutubePlayer
                  ? (MediaQuery.of(context).size.width / (16 / 9)) +
                      56.0 + // approximate header height
                      MediaQuery.of(context).padding.bottom +
                      20.0 // extra breathing room
                  : 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Name
                if (_artistName.isNotEmpty && _artistName != 'UNKNOWN')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Author: $_artistName',
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic),
                    ),
                  ),

                // Key Info & Language Switcher Row
                Padding(
                  padding: EdgeInsets.only(
                      bottom: 16.0,
                      top: _artistName.isNotEmpty && _artistName != 'UNKNOWN'
                          ? 4.0
                          : 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Key Information
                      Text(
                        'Key: $displayKey',
                        style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic),
                      ),

                      // Right Side: Language Switcher Chips & YouTube
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_youtubeVideoId != null)
                            Padding(
                              padding: EdgeInsets.only(
                                  right:
                                      (widget.tabData['trans_lines'] != null &&
                                              (widget.tabData['trans_lines']
                                                      as List)
                                                  .isNotEmpty)
                                          ? 8.0
                                          : 0.0),
                              child: SizedBox(
                                height: 32.0,
                                child: TextButton.icon(
                                  icon: const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 16),
                                  label: Text(
                                    'YouTube',
                                    style: textTheme.labelMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () {
                                    _performVibration();
                                    _launchYoutubePlayer(_youtubeVideoId!);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    backgroundColor: Colors.red.shade600,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    minimumSize: const Size(0, 32.0),
                                    splashFactory: InkSparkle.splashFactory,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.tabData['trans_lines'] != null &&
                              (widget.tabData['trans_lines'] as List)
                                  .isNotEmpty)
                            Builder(builder: (context) {
                              final String songCategory =
                                  widget.tabData['category'] as String;
                              final String? songLanguage =
                                  widget.tabData['language'] as String?;

                              String nativeLangName = 'Original';

                              if (songLanguage != null &&
                                  songLanguage.isNotEmpty) {
                                // Direct language definition takes precedence
                                nativeLangName = songLanguage[0].toUpperCase() +
                                    songLanguage.substring(1).toLowerCase();
                              } else {
                                // Fallback to category if language is null/empty
                                if (songCategory == 'kannada' ||
                                    songCategory == 'kannada_data') {
                                  nativeLangName = 'Kannada';
                                } else if (songCategory == 'english' ||
                                    songCategory == 'english_data') {
                                  nativeLangName = 'English';
                                } else {
                                  nativeLangName = 'Original';
                                }
                              }
                              return _buildLanguageChips(
                                  context, nativeLangName);
                            }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Font Size & Controls Bar
                if (hasAnyChords)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Right Side: Transpose & Chords
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Show/Hide Chords Button
                            SizedBox(
                              height: _kControlsButtonHeight,
                              child: TextButton.icon(
                                icon: Icon(
                                    _showChords
                                        ? Icons.music_off_rounded
                                        : Icons.music_note_rounded,
                                    color: colorScheme.primary,
                                    size: 20),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        _showChords
                                            ? 'Hide Chords'
                                            : 'Show Chords',
                                        style: textTheme.labelMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('BETA',
                                          style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                onPressed: () {
                                  _performVibration();
                                  setState(() => _showChords = !_showChords);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  backgroundColor: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  minimumSize:
                                      const Size(0, _kControlsButtonHeight),
                                  splashFactory: InkSparkle.splashFactory,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Transpose Controls Group
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTransposeButton(context,
                                    icon: Icons.remove, onTap: () {
                                  _performVibration();
                                  setState(() => _transposeSemitones--);
                                }, tooltip: "Transpose Down"),
                                Container(
                                  height: _kControlsButtonHeight,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_transposeSemitones > 0 ? '+' : ''}${_transposeSemitones}',
                                    style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                                _buildTransposeButton(context, icon: Icons.add,
                                    onTap: () {
                                  _performVibration();
                                  setState(() => _transposeSemitones++);
                                }, tooltip: "Transpose Up"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  color: colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          _buildSongLines(context, hasAnyChords, _fontSize),
                    ),
                  ),
                ),
                if (_authorForCopyright.isNotEmpty &&
                    _authorForCopyright != 'UNKNOWN')
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 5.0),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '© ',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.6),
                                fontSize: 18, // Larger symbol
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: _authorForCopyright,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.6),
                                fontSize: textTheme.bodySmall?.fontSize,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Persistent YouTube overlay player (non-blocking)
          if (_showYoutubePlayer && _ytController != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInlineYoutubePlayer(context, colorScheme, textTheme),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isMaster)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                heroTag: 'deleteBtn',
                onPressed: () {
                  _performVibration();
                  _confirmDeleteSong(context);
                },
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_forever_rounded),
              ),
            ),
          FloatingActionButton(
            heroTag: 'fontSizeBtn',
            onPressed: () {
              _performVibration();
              _showFontSizeBottomSheet(context, colorScheme, textTheme);
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.format_size_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineYoutubePlayer(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth / (16 / 9);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + close button header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Now Playing',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20,
                  color: colorScheme.onSurfaceVariant,
                  onPressed: _closeYoutubePlayer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Player
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: SizedBox(
              height: playerHeight,
              width: double.infinity,
              child: YoutubePlayer(
                controller: _ytController!,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          // Bottom safe-area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _launchYoutubePlayer(String videoId) {
    // Close any existing controller before opening a new one
    _ytController?.close();
    setState(() {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          loop: true,
          pointerEvents: PointerEvents.auto,
          origin: 'https://www.youtube-nocookie.com',
          enableCaption: false,
        ),
      );
      _showYoutubePlayer = true;
    });
  }

  void _showFontSizeBottomSheet(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 500),
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adjust Font Size',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrease Size Button
                      _buildSizeControlButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_fontSize > 12) {
                            _performVibration();
                            setState(() => _fontSize -= 2);
                            setBottomSheetState(() {});
                          }
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 20),
                      // Current Size Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _fontSize.toInt().toString(),
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Increase Size Button
                      _buildSizeControlButton(
                        icon: Icons.add,
                        onTap: () {
                          if (_fontSize < 36) {
                            _performVibration();
                            setState(() => _fontSize += 2);
                            setBottomSheetState(() {});
                          }
                        },
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSizeControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.primary),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  List<Widget> _buildSongLines(
      BuildContext context, bool hasAnyChords, double fontSize) {
    final List<Widget> widgets = [];
    List<Map<String, dynamic>>? pendingChords;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    bool firstLyricLine = true;

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i] as Map<String, dynamic>;
      if (line['type'] == 'blank') {
        widgets.add(const SizedBox(height: 10));
        firstLyricLine = true;
      } else if (line['type'] == 'chords' && _showChords && hasAnyChords) {
        pendingChords = (line['chords'] as List)
            .map((chordData) => {
                  'note': transposeChord(
                      chordData['note'] as String? ?? '', _transposeSemitones),
                  'pre_spaces': chordData['pre_spaces'] as int? ?? 0,
                })
            .toList();
      } else if (line['type'] == 'lyric') {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: firstLyricLine ? 0 : 6.0, bottom: 2.0),
          child: ChordLyricLine(
            lyric: line['lyric'] ?? '',
            chords: _showChords && hasAnyChords ? pendingChords : null,
            colorScheme: colorScheme,
            textTheme: textTheme,
            fontSize: fontSize,
          ),
        ));
        pendingChords = null;
        firstLyricLine = false;
      }
    }
    return widgets;
  }

  // ─── LANGUAGE SWITCHER ───────────────────────────────────────────────────
  Widget _buildLanguageChips(BuildContext context, String nativeLangName) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageChip(
            context: context,
            label: nativeLangName,
            isSelected: !_showTransliteration,
            onTap: () {
              if (_showTransliteration) {
                _performVibration();
                setState(() => _showTransliteration = false);
              }
            },
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
          _buildLanguageChip(
            context: context,
            label: 'English', // English is always the transliteration target
            isSelected: _showTransliteration,
            onTap: () {
              if (!_showTransliteration) {
                _performVibration();
                setState(() => _showTransliteration = true);
              }
            },
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.6)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, _kControlsButtonHeight),
          splashFactory: InkSparkle.splashFactory,
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTransposeButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap, String? tooltip}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: _kControlsButtonHeight,
      width: _kControlsButtonHeight + 4,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: colorScheme.primary),
          onPressed: onTap,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          iconSize: 20,
        ),
      ),
    );
  }
}

class ChordLyricLine extends StatelessWidget {
  final String lyric;
  final List<Map<String, dynamic>>? chords;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double fontSize;

  const ChordLyricLine({
    super.key,
    required this.lyric,
    this.chords,
    required this.colorScheme,
    required this.textTheme,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final lyricStyle = textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: fontSize,
      height: 1.6,
      letterSpacing: 0.2,
    );
    final chordStyle = textTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      fontSize: fontSize - 1,
    );

    if (lyric.trim().isEmpty && (chords == null || chords!.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (chords == null || chords!.isEmpty) {
      return Text(lyric, style: lyricStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChordsRow(chordStyle),
        const SizedBox(height: 2),
        Text(lyric, style: lyricStyle),
      ],
    );
  }

  Widget _buildChordsRow(TextStyle? chordStyle) {
    if (chords == null || chords!.isEmpty) return const SizedBox.shrink();
    final TextStyle effectiveChordStyle = chordStyle ??
        textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 15,
        ) ??
        const TextStyle();

    List<Widget> chordWidgets = [];
    int currentTextPos = 0;

    for (final chordData in chords!) {
      final preSpaces = chordData['pre_spaces'] as int? ?? 0;
      final note = chordData['note'] as String? ?? '';

      if (note.isNotEmpty) {
        if (preSpaces > currentTextPos) {
          chordWidgets.add(SizedBox(width: (preSpaces - currentTextPos) * 7.0));
        }
        chordWidgets.add(Text(note, style: effectiveChordStyle));
        currentTextPos = preSpaces + note.length;
      } else if (preSpaces > currentTextPos) {
        chordWidgets.add(SizedBox(width: (preSpaces - currentTextPos) * 7.0));
        currentTextPos = preSpaces;
      }
    }
    return Row(children: chordWidgets);
  }
}

class _YoutubeBottomSheet extends StatefulWidget {
  final String videoId;

  const _YoutubeBottomSheet({required this.videoId});

  @override
  State<_YoutubeBottomSheet> createState() => _YoutubeBottomSheetState();
}

class _YoutubeBottomSheetState extends State<_YoutubeBottomSheet> {
  YoutubePlayerController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wait for the Bottom Sheet animation to completely finish before
    // initializing the webview iframe. This avoids the 'setSize' JS error
    // completely by ensuring the iframe has a solid, final layout boundary.
    final route = ModalRoute.of(context);
    if (route != null && _controller == null) {
      if (route.animation?.isCompleted == true) {
        _initController();
      } else {
        route.animation?.addStatusListener((status) {
          if (status == AnimationStatus.completed && _controller == null) {
            _initController();
          }
        });
      }
    }
  }

  void _initController() {
    if (!mounted) return;
    setState(() {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          loop: true,
          pointerEvents: PointerEvents.auto,
          // Using privacy-enhanced nocookie domain works around the
          // 'SyntaxError: Invalid or unexpected token' JS error from YouTube's
          // latest API when loaded inside a native Android WebView.
          origin: 'https://www.youtube-nocookie.com',
          enableCaption: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate 16:9 ratio for the player to reserve fixed height
    // before the controller initializes
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = (screenWidth - 32) / (16 / 9);

    return Padding(
      // Accommodate screen padding/safe areas
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: playerHeight,
                width: double.infinity,
                child: _controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : YoutubePlayer(
                        controller: _controller!,
                        aspectRatio: 16 / 9,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
