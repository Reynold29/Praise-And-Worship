import 'dart:io';
import '../utils/app_logger.dart';

/// Probes each URL in order and returns the first one that responds
/// within [timeoutMs] milliseconds.
///
/// Strategy:
///   1. Try [primary] with a short TCP-level connect (no full handshake).
///   2. If it succeeds (or returns ANY HTTP status ≤ 5xx) within the timeout,
///      use it — we just need to know the host is reachable.
///   3. On timeout or connection-refused, try [fallback] immediately.
///   4. If fallback also fails, return [primary] so the app can still attempt
///      to use its cached session data offline.
class SupabaseUrlResolver {
  SupabaseUrlResolver._();
  static final SupabaseUrlResolver instance = SupabaseUrlResolver._();

  /// Resolves the best reachable Supabase URL.
  ///
  /// [primary]     — e.g. https://xyz.supabase.co
  /// [fallback]    — e.g. https://praise-worship-auth.jiobase.com
  /// [timeoutMs]   — per-URL probe timeout in milliseconds (default 2 500 ms)
  Future<String> resolve({
    required String primary,
    required String fallback,
    int timeoutMs = 2500,
  }) async {
    final timeout = Duration(milliseconds: timeoutMs);

    // ── Probe helper ────────────────────────────────────────────────────────
    // Opens a raw socket to port 443 of the host. This is a pure TCP connect —
    // no TLS/HTTP involved — so it's very fast and doesn't waste bandwidth.
    Future<bool> canReach(String url) async {
      try {
        final host = Uri.parse(url).host;
        final socket = await Socket.connect(
          host,
          443,
          timeout: timeout,
        );
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }

    // ── Try primary ─────────────────────────────────────────────────────────
    AppLogger.d('UrlResolver', 'Probing primary: $primary');
    if (await canReach(primary)) {
      AppLogger.d('UrlResolver', 'Primary reachable ✓');
      return primary;
    }

    // ── Try fallback ────────────────────────────────────────────────────────
    AppLogger.d('UrlResolver', 'Primary unreachable — trying fallback');
    if (await canReach(fallback)) {
      AppLogger.d('UrlResolver', 'Fallback reachable ✓');
      return fallback;
    }

    // ── Both failed (offline?) → return primary for cached operation ────────
    AppLogger.w('UrlResolver', 'Both URLs unreachable — defaulting to primary');
    return primary;
  }
}
