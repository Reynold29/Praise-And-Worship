import 'package:flutter/foundation.dart';

/// Centralised logging utility.
///
/// - In **debug** builds: prints structured, prefixed messages to the console.
/// - In **release / profile** builds: all calls are compiled away — zero cost.
///
/// Usage:
///   AppLogger.d('tag', 'message');   // debug
///   AppLogger.e('tag', 'message');   // error (always visible in debug)
///   AppLogger.w('tag', 'message');   // warning
abstract final class AppLogger {
  // ── Debug (debug builds only) ──────────────────────────────────────────────
  static void d(String tag, String msg) {
    if (kDebugMode) debugPrint('[$tag] $msg');
  }

  // ── Warning (debug builds only) ───────────────────────────────────────────
  static void w(String tag, String msg) {
    if (kDebugMode) debugPrint('[WARN/$tag] $msg');
  }

  // ── Error (debug builds only; use for caught exceptions) ──────────────────
  static void e(String tag, String msg, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR/$tag] $msg${error != null ? ' | $error' : ''}');
    }
  }
}
