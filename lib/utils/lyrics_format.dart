import 'package:flutter/services.dart';

/// Helpers so pasted and displayed lyrics keep exact spacing.
class LyricsFormat {
  LyricsFormat._();

  /// Normalize clipboard/web paste without collapsing intentional spaces.
  ///
  /// - CRLF / CR → LF
  /// - non-breaking / exotic spaces → regular space (still one space each)
  /// - keeps leading/trailing spaces and blank lines
  /// - does **not** trim lines
  static String normalizePaste(String raw) {
    if (raw.isEmpty) return raw;
    var text = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Common web paste space variants → regular space (same width intent)
        .replaceAll('\u00A0', ' ') // NBSP
        .replaceAll('\u202F', ' ') // narrow NBSP
        .replaceAll('\u2007', ' ') // figure space
        .replaceAll('\u2009', ' ') // thin space
        .replaceAll('\u200A', ' ') // hair space
        .replaceAll('\t', '    '); // tabs → 4 spaces (visible & stable)

    // Strip a single trailing newline often added by "Copy" on web,
    // but keep internal blank lines.
    if (text.endsWith('\n') && !text.endsWith('\n\n')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// Flutter [Text] collapses consecutive regular spaces. Use NBSP for display.
  static String preserveForDisplay(String lyric) {
    if (lyric.isEmpty) return lyric;
    return lyric.replaceAll(' ', '\u00A0');
  }
}

/// Keeps pasted lyrics/chords exactly as copied (spaces, blank lines, tabs).
class PreservePasteFormatter extends TextInputFormatter {
  const PreservePasteFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    final needsNorm = t.contains('\r') ||
        t.contains('\u00A0') ||
        t.contains('\t') ||
        (t.length - oldValue.text.length) > 8;
    if (!needsNorm) return newValue;

    final normalized = LyricsFormat.normalizePaste(t);
    if (normalized == t) return newValue;

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
