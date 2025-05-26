import 'package:flutter/material.dart';
import 'dart:math' as math;

class SongDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tabData; // expects the parsed 'tab' object from your API

  const SongDetailScreen({super.key, required this.tabData});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  bool _showChords = false;
  int _transposeSemitones = 0;
  String? _originalKeyFromDB;
  String? _derivedKeyFromChords;

  List<dynamic> get _lines => widget.tabData['lines'] as List<dynamic>;
  String get _title => widget.tabData['title'] ?? 'Untitled';
  String get _artistName => widget.tabData['artist_name'] ?? ''; // Used for "Author: ..."
  String get _authorForCopyright => widget.tabData['author'] ?? ''; // Used for copyright

  static const double _kControlsButtonHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _originalKeyFromDB = widget.tabData['key_signature'] as String?;
    if (_originalKeyFromDB == null || _originalKeyFromDB!.isEmpty) {
      _derivedKeyFromChords = _findOriginalKeyFromChords();
    }
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
    final keyToUse = _originalKeyFromDB?.isNotEmpty == true ? _originalKeyFromDB : _derivedKeyFromChords;
    if (keyToUse == null || keyToUse.isEmpty) return "N/A";
    return _transposeNote(keyToUse, _transposeSemitones);
  }
   String get originalDisplayKey {
    return _originalKeyFromDB?.isNotEmpty == true ? _originalKeyFromDB! : (_derivedKeyFromChords ?? "N/A");
  }

  String transposeChord(String chord, int semitones) {
    if (semitones == 0) return chord;
    return _transposeChordInternal(chord, semitones);
  }

  static const List<String> _notesSharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const List<String> _notesFlat =  ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

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
    final RegExp chordRegex = RegExp(r'^([A-Ga-g][#b]?)([^/]*)(?:/([A-Ga-g][#b]?))?');
    final match = chordRegex.firstMatch(chord);
    if (match == null) return chord;

    String root = match.group(1)!;
    String quality = match.group(2) ?? '';
    String? bassNote = match.group(3);

    String transposedRoot = _transposeNote(root, semitones);
    String? transposedBass = bassNote != null ? _transposeNote(bassNote, semitones) : null;

    return transposedRoot + quality + (transposedBass != null ? '/${_transposeNote(transposedBass, 0)}' : '');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool hasAnyChords = true; // Always show controls

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Name
            if (_artistName.isNotEmpty && _artistName != 'UNKNOWN')
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Author: $_artistName',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                ),
              ),
            // Key Info
            if (originalDisplayKey != "N/A" || hasAnyChords)
              Padding(
                padding: EdgeInsets.only(bottom: 16.0, top: _artistName.isNotEmpty && _artistName != 'UNKNOWN' ? 4.0 : 0),
                child: Text(
                  'Key: $originalDisplayKey',
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                ),
              ),
            
            // Controls Bar
            if (hasAnyChords)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, 
                  children: [
                    // Show/Hide Chords Button
                    SizedBox(
                      height: _kControlsButtonHeight,
                      child: TextButton.icon(
                        icon: Icon(_showChords ? Icons.music_off_rounded : Icons.music_note_rounded, color: colorScheme.primary, size: 20),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_showChords ? 'Hide Chords' : 'Show Chords', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('BETA', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer, fontSize: 8, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        onPressed: () => setState(() => _showChords = !_showChords),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12), 
                          backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                          minimumSize: const Size(0, _kControlsButtonHeight), 
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Transpose Controls Group
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTransposeButton(context, icon: Icons.remove, onTap: () => setState(() => _transposeSemitones--), tooltip: "Transpose Down"),
                        Container(
                          height: _kControlsButtonHeight,
                          alignment: Alignment.center, 
                          padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_transposeSemitones > 0 ? '+' : ''}${_transposeSemitones}',
                            style: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        _buildTransposeButton(context, icon: Icons.add, onTap: () => setState(() => _transposeSemitones++), tooltip: "Transpose Up"),
                      ],
                    )
                  ],
                ),
              ),

            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              color: colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                   children: _buildSongLines(context, hasAnyChords),
                ),
              ),
            ),
            if (_authorForCopyright.isNotEmpty && _authorForCopyright != 'UNKNOWN')
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 5.0),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '© ',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 18, // Larger symbol
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: _authorForCopyright,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
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
    );
  }

  Widget _buildTransposeButton(BuildContext context, {required IconData icon, required VoidCallback onTap, String? tooltip}) {
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

  List<Widget> _buildSongLines(BuildContext context, bool hasAnyChords) {
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
                  'note': transposeChord(chordData['note'] as String? ?? '', _transposeSemitones),
                  'pre_spaces': chordData['pre_spaces'] as int? ?? 0,
                })
            .toList();
      } else if (line['type'] == 'lyric') {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: firstLyricLine ? 0 : 6.0, bottom: 2.0),
            child: ChordLyricLine(
              lyric: line['lyric'] ?? '',
              chords: _showChords && hasAnyChords ? pendingChords : null,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          )
        );
        pendingChords = null;
        firstLyricLine = false;
      }
    }
    return widgets;
  }
}

class ChordLyricLine extends StatelessWidget {
  final String lyric;
  final List<Map<String, dynamic>>? chords;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const ChordLyricLine({
    super.key,
    required this.lyric,
    this.chords,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final lyricStyle = textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: 17,
      height: 1.6,
      letterSpacing: 0.2,
    );
    final chordStyle = textTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5, 
      fontSize: 15, 
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
    final TextStyle effectiveChordStyle = chordStyle ?? textTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5, 
      fontSize: 15, 
    ) ?? const TextStyle();

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