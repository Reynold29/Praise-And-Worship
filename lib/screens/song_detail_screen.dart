import 'dart:async';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/widgets/playlist_provider.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:worshipcompanion/widgets/share_qr_dialog.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:worshipcompanion/utils/lyrics_format.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:worshipcompanion/screens/edit_song_screen.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
import 'package:worshipcompanion/services/local_database_service.dart';

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
  bool _hideActions = false;
  bool _showMasterFabs = true;
  Timer? _masterFabHideTimer;

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

  @override
  void initState() {
    super.initState();
    _originalKeyFromDB = widget.tabData['key_signature'] as String?;
    if (_originalKeyFromDB == null || _originalKeyFromDB!.isEmpty) {
      _derivedKeyFromChords = _findOriginalKeyFromChords();
    }
    _scheduleMasterFabHide();
  }

  @override
  void dispose() {
    _masterFabHideTimer?.cancel();
    _ytController?.close();
    super.dispose();
  }

  void _bumpMasterFabVisibility() {
    if (!_showMasterFabs) {
      setState(() => _showMasterFabs = true);
    }
    _scheduleMasterFabHide();
  }

  void _scheduleMasterFabHide() {
    _masterFabHideTimer?.cancel();
    _masterFabHideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_showMasterFabs) return;
      setState(() => _showMasterFabs = false);
    });
  }

  void _showQRShareDialog() async {
    _performVibration();
    if (!await ConnectivityGuard.ensureOnline(context,
        message:
            'Sharing needs internet so others can open the link from the QR.')) {
      return;
    }
    if (!mounted) return;
    final config = Provider.of<AppConfigProvider>(context, listen: false);
    final category = (widget.tabData['category'] ?? '').toString();
    final songId = widget.tabData['id']?.toString() ?? '';

    if (songId.isEmpty || songId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This song has no id to share.')),
      );
      return;
    }

    String langCode = 'other';
    if (category == 'english' || category == 'english_data') {
      langCode = 'english';
    } else if (category == 'kannada' || category == 'kannada_data') {
      langCode = 'kannada';
    }

    showShareQrDialog(
      context: context,
      heading: 'Share Song',
      subtitle: 'Anyone can scan this to open the lyrics',
      qrUrl: '${config.qrBaseUrl}/lyrics?l=$langCode&id=$songId',
      caption: _title,
      detail: _artistName,
    );
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
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Deleting a song needs an internet connection.',
        useDialog: true)) {
      return;
    }
    if (!mounted) return;
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
      await LocalDatabaseService.instance.syncAllCategories(force: true);
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
        appConfigProvider.isMasterUser(authProvider.email);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: 64,
        clipBehavior: Clip.none,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                height: 32,
                child: M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  shape: M3EButtonShape.round,
                  size: M3EButtonSize.xs,
                  style: M3EButtonStyle.tonal,
                  density: M3EButtonGroupDensity.compact,
                  neighborSquish: true,
                  overflow: M3EButtonGroupOverflow.scroll,
                  haptic: M3EHapticFeedback.light,
                  decoration: _groupDecoration,
                  selectedIndices: {
                    if (isFavorite) 1,
                  },
                  onSelectedIndicesChanged: (indices) {
                    if (indices.contains(0)) {
                      _showQRShareDialog();
                    }
                    final wantFavorite = indices.contains(1);
                    if (wantFavorite != isFavorite) {
                      _toggleFavorite(
                        favoriteProvider,
                        songCategory,
                        songId,
                        isFavorite,
                      );
                    }
                  },
                  actions: const [
                    M3EButtonGroupAction(
                      icon: Icon(Icons.qr_code_2_rounded),
                      label: Text('Share Song'),
                    ),
                    M3EButtonGroupAction(
                      icon: Icon(Icons.favorite_border_rounded),
                      checkedIcon: Icon(Icons.favorite_rounded),
                      label: Text('Favorite'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (isMaster) _bumpMasterFabVisibility();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (isMaster && notification is ScrollUpdateNotification) {
              _bumpMasterFabVisibility();
            }
            return false;
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 12.0,
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
                    _buildSongInfoCard(
                      context,
                      hasAnyChords,
                      songId,
                      songCategory,
                    ),
                    const SizedBox(height: 16),
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
                          children: _buildSongLines(
                              context, hasAnyChords, _fontSize),
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
                  child: _buildInlineYoutubePlayer(
                      context, colorScheme, textTheme),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: isMaster
          ? IgnorePointer(
              ignoring: !_showMasterFabs,
              child: AnimatedOpacity(
                opacity: _showMasterFabs ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'editBtn',
                      onPressed: () async {
                        _performVibration();
                        _bumpMasterFabVisibility();
                        final navigator = Navigator.of(context);
                        if (!await ConnectivityGuard.ensureOnline(context,
                            message:
                                'Editing a song needs an internet connection.',
                            useDialog: true)) {
                          return;
                        }
                        if (!mounted) return;
                        final updated = await navigator.push(
                          snappyPageRoute(
                            page: EditSongScreen(tabData: widget.tabData),
                          ),
                        );
                        if (updated != null && updated is Map<String, dynamic> && mounted) {
                          setState(() {
                            widget.tabData.addAll(updated);
                            _originalKeyFromDB = widget.tabData['key_signature'] as String?;
                          });
                        }
                      },
                      child: const Icon(Icons.edit_rounded),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'deleteBtn',
                      onPressed: () {
                        _performVibration();
                        _bumpMasterFabVisibility();
                        _confirmDeleteSong(context);
                      },
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete_forever_rounded),
                    ),
                  ],
                ),
              ),
            )
          : null,
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

  Widget _buildSongInfoCard(
    BuildContext context,
    bool hasAnyChords,
    String songId,
    String songCategory,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final genre = widget.tabData['genre'] as String?;
    final author = _artistName.trim();
    final showAuthor = author.isNotEmpty && author.toUpperCase() != 'UNKNOWN';

    return Material(
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SongIdentityBlock(
              indexLabel: 'SONG',
              chipLabel: SongUtils.chipLabel(songCategory, genre),
              title: _title,
              titleSize: 16,
              keyLabel: displayKey != 'N/A' ? 'Key: $displayKey' : null,
              authorLabel: showAuthor ? author : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            _buildControlBars(
              context,
              hasAnyChords,
              songId,
              songCategory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBars(
    BuildContext context,
    bool hasAnyChords,
    String songId,
    String songCategory,
  ) {
    // One Material Expressive control chrome for every language.
    // Non-English songs get an extra Native / English toggle when transliteration exists.
    return _buildExpressiveControlBars(
      context,
      hasAnyChords,
      songId,
      songCategory,
    );
  }

  static const _kSpringMotion = M3EButtonMotion.expressiveSpatialPress;
  static const _kConnectedDivider = 2.0;
  static final _kStepperSize = M3EButtonSize.custom(height: 40, hPadding: 4);

  M3EButtonDecoration get _buttonDecoration => M3EButtonDecoration(
        motion: _kSpringMotion,
        haptic: M3EHapticFeedback.light,
      );

  M3EToggleButtonDecoration get _groupDecoration =>
      M3EToggleButtonDecoration.styleFrom(
        motion: _kSpringMotion,
        haptic: M3EHapticFeedback.light,
      );

  String _nativeLangName(String songCategory) {
    final songLanguage = widget.tabData['language'] as String?;
    if (songLanguage != null && songLanguage.isNotEmpty) {
      return songLanguage[0].toUpperCase() +
          songLanguage.substring(1).toLowerCase();
    }
    if (songCategory == 'kannada' || songCategory == 'kannada_data') {
      return 'Kannada';
    }
    if (songCategory == 'english' || songCategory == 'english_data') {
      return 'English';
    }
    return 'Original';
  }

  Widget _buildExpressiveControlBars(
    BuildContext context,
    bool hasAnyChords,
    String songId,
    String songCategory,
  ) {
    final hasAudio = _youtubeVideoId != null;
    final transposeEnabled = hasAnyChords && _showChords;
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish =
        songCategory == 'english' || songCategory == 'english_data';
    final hasTrans = !isEnglish &&
        widget.tabData['trans_lines'] != null &&
        (widget.tabData['trans_lines'] as List).isNotEmpty;
    final nativeLangName = _nativeLangName(songCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _hideActions
              ? const SizedBox(width: double.infinity)
              : Column(
                  children: [
                    if (hasTrans) ...[
                      SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final segment = _connectedSegmentWidth(
                              constraints.maxWidth,
                              2,
                            );
                            return M3EButtonGroup(
                              type: M3EButtonGroupType.connected,
                              shape: M3EButtonShape.round,
                              size: M3EButtonSize.sm,
                              style: M3EButtonStyle.tonal,
                              density: M3EButtonGroupDensity.compact,
                              neighborSquish: true,
                              overflow: M3EButtonGroupOverflow.none,
                              haptic: M3EHapticFeedback.light,
                              decoration: _groupDecoration,
                              selectedIndices: {
                                if (_showTransliteration) 1 else 0,
                              },
                              onSelectedIndicesChanged: (indices) {
                                final wantEnglish = indices.contains(1);
                                if (wantEnglish != _showTransliteration) {
                                  _performVibration();
                                  setState(
                                      () => _showTransliteration = wantEnglish);
                                }
                              },
                              actions: [
                                M3EButtonGroupAction(
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(nativeLangName),
                                  ),
                                  width: segment,
                                ),
                                M3EButtonGroupAction(
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('English'),
                                  ),
                                  width: segment,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final segment = _connectedSegmentWidth(
                            constraints.maxWidth,
                            3,
                          );
                          return M3EButtonGroup(
                            type: M3EButtonGroupType.connected,
                            shape: M3EButtonShape.round,
                            size: M3EButtonSize.sm,
                            style: M3EButtonStyle.tonal,
                            density: M3EButtonGroupDensity.compact,
                            neighborSquish: true,
                            overflow: M3EButtonGroupOverflow.none,
                            haptic: M3EHapticFeedback.light,
                            decoration: _groupDecoration,
                            selectedIndices: {
                              if (_showChords) 1,
                            },
                            onSelectedIndicesChanged: (indices) {
                              if (indices.contains(0)) {
                                _showAddToPlaylistSheet(songId, songCategory);
                              }
                              if (indices.contains(2) && hasAudio) {
                                _performVibration();
                                _launchYoutubePlayer(_youtubeVideoId!);
                              }
                              final wantChords =
                                  hasAnyChords && indices.contains(1);
                              if (wantChords != _showChords) {
                                _performVibration();
                                setState(() => _showChords = wantChords);
                              }
                            },
                            actions: [
                              M3EButtonGroupAction(
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Playlist'),
                                ),
                                width: segment,
                              ),
                              M3EButtonGroupAction(
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Chords'),
                                ),
                                width: segment,
                                enabled: hasAnyChords,
                              ),
                              M3EButtonGroupAction(
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Audio'),
                                ),
                                width: segment,
                                enabled: hasAudio,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const fontW = 168.0;
                        const gap = 8.0;
                        final leftover =
                            (constraints.maxWidth - fontW - gap).clamp(120.0, 400.0);
                        return Row(
                          children: [
                            SizedBox(
                              width: fontW,
                              child: _m3eStepper(
                                colorScheme: colorScheme,
                                leadingLabel: 'Font',
                                value: _fontSize.toInt().toString(),
                                sideWidth: 36,
                                numberWidth: 40,
                                labelWidth: 48,
                                onMinus: () {
                                  if (_fontSize > 12) {
                                    _performVibration();
                                    setState(() => _fontSize -= 2);
                                  }
                                },
                                onPlus: () {
                                  if (_fontSize < 36) {
                                    _performVibration();
                                    setState(() => _fontSize += 2);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: gap),
                            SizedBox(
                              width: leftover,
                              child: _m3eStepper(
                                colorScheme: colorScheme,
                                leadingLabel: 'Tp',
                                value: _transposeSemitones == 0
                                    ? '0'
                                    : '${_transposeSemitones > 0 ? '+' : ''}$_transposeSemitones',
                                enabled: transposeEnabled,
                                sideWidth: 36,
                                numberWidth: 40,
                                labelWidth: 36,
                                onMinus: () {
                                  _performVibration();
                                  setState(() => _transposeSemitones--);
                                },
                                onPlus: () {
                                  _performVibration();
                                  setState(() => _transposeSemitones++);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
        ),
        Align(
          alignment: Alignment.center,
          child: M3EButton.filled(
            onPressed: () {
              _performVibration();
              setState(() => _hideActions = !_hideActions);
            },
            shape: M3EButtonShape.round,
            size: M3EButtonSize.xs,
            decoration: _buttonDecoration,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Text(
                _hideActions ? 'Show Controls' : 'Hide Controls',
                key: ValueKey(_hideActions),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _connectedSegmentWidth(double maxWidth, int count) {
    final usable = maxWidth - _kConnectedDivider * (count - 1);
    return (usable / count).floorToDouble().clamp(0.0, maxWidth);
  }

  Widget _m3eStepper({
    required ColorScheme colorScheme,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required double sideWidth,
    required double numberWidth,
    String? leadingLabel,
    double? labelWidth,
    bool enabled = true,
  }) {
    final valueStyle = M3EToggleButtonDecoration.styleFrom(
      motion: _kSpringMotion,
      haptic: M3EHapticFeedback.none,
      foregroundColor: colorScheme.onSurface,
      disabledForegroundColor: colorScheme.onSurface,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: SizedBox(
          height: 40,
          width: double.infinity,
          child: M3EButtonGroup(
            type: M3EButtonGroupType.connected,
            shape: M3EButtonShape.round,
            size: _kStepperSize,
            style: M3EButtonStyle.tonal,
            density: M3EButtonGroupDensity.compact,
            neighborSquish: false,
            overflow: M3EButtonGroupOverflow.none,
            haptic: M3EHapticFeedback.light,
            decoration: _groupDecoration,
            selectedIndex: null,
            onSelectedIndexChanged: (index) {
              if (index == null) return;
              if (leadingLabel != null) {
                if (index == 1) onMinus();
                if (index == 3) onPlus();
              } else {
                if (index == 0) onMinus();
                if (index == 2) onPlus();
              }
            },
            actions: [
              if (leadingLabel != null)
                M3EButtonGroupAction(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(leadingLabel),
                  ),
                  width: labelWidth,
                ),
              M3EButtonGroupAction(
                icon: const Icon(Icons.remove_rounded),
                width: sideWidth,
                enabled: enabled,
              ),
              M3EButtonGroupAction(
                label: Text(
                  value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                width: numberWidth,
                decoration: valueStyle,
              ),
              M3EButtonGroupAction(
                icon: const Icon(Icons.add_rounded),
                width: sideWidth,
                enabled: enabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(
    FavoriteProvider favoriteProvider,
    String songCategory,
    String songId,
    bool isFavorite,
  ) {
    _performVibration();
    favoriteProvider.toggleFavorite(songCategory, songId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isFavorite ? 'Removed from favorites' : 'Added to favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showAddToPlaylistSheet(String songId, String category) async {
    _performVibration();
    final playlistProv = Provider.of<PlaylistProvider>(context, listen: false);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Add to playlist',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (playlistProv.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No playlists yet. Create one first.'),
                ),
              ...playlistProv.playlists.map((p) {
                final already = playlistProv.isSongInPlaylist(p.id, songId);
                return ListTile(
                  leading: const Icon(Icons.playlist_play_rounded),
                  title: Text(p.name),
                  trailing: already ? const Icon(Icons.check_rounded) : null,
                  onTap: already
                      ? null
                      : () async {
                          try {
                            await playlistProv.addSongToPlaylist(
                                p.id, songId, category);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to ${p.name}')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                );
              }),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: const Text('New playlist'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (_) => const _QuickCreatePlaylistDialog(),
                  );
                  if (created == true && mounted) {
                    await _showAddToPlaylistSheet(songId, category);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _QuickCreatePlaylistDialog extends StatefulWidget {
  const _QuickCreatePlaylistDialog();

  @override
  State<_QuickCreatePlaylistDialog> createState() =>
      _QuickCreatePlaylistDialogState();
}

class _QuickCreatePlaylistDialogState
    extends State<_QuickCreatePlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist name'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            try {
              await Provider.of<PlaylistProvider>(context, listen: false)
                  .createPlaylist(name);
              if (context.mounted) Navigator.pop(context, true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
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
      fontFamily: 'ProductSans',
    );
    final chordStyle = textTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      fontSize: fontSize - 1,
      fontFamily: 'ProductSans',
    );

    // Preserve blank lines between verses (do not drop empty lyric rows).
    if (lyric.trim().isEmpty && (chords == null || chords!.isEmpty)) {
      return SizedBox(height: fontSize * 1.35);
    }

    final displayLyric = LyricsFormat.preserveForDisplay(lyric);

    if (chords == null || chords!.isEmpty) {
      return Text(displayLyric, style: lyricStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChordsRow(chordStyle),
        const SizedBox(height: 2),
        Text(displayLyric, style: lyricStyle),
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
          fontFamily: 'ProductSans',
        ) ??
        const TextStyle(fontFamily: 'ProductSans');

    final spacePainter = TextPainter(
      text: TextSpan(text: ' ', style: effectiveChordStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final spaceWidth = spacePainter.width.clamp(4.0, 14.0);
    spacePainter.dispose();

    List<Widget> chordWidgets = [];
    int currentTextPos = 0;

    for (final chordData in chords!) {
      final preSpaces = chordData['pre_spaces'] as int? ?? 0;
      final note = chordData['note'] as String? ?? '';

      if (note.isNotEmpty) {
        if (preSpaces > currentTextPos) {
          chordWidgets.add(
              SizedBox(width: (preSpaces - currentTextPos) * spaceWidth));
        }
        chordWidgets.add(Text(note, style: effectiveChordStyle));
        currentTextPos = preSpaces + note.length;
      } else if (preSpaces > currentTextPos) {
        chordWidgets
            .add(SizedBox(width: (preSpaces - currentTextPos) * spaceWidth));
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
