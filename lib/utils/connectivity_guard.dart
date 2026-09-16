import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';

/// Shared online check for local-first flows.
class ConnectivityGuard {
  ConnectivityGuard._();

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    if (result.isEmpty) return true;
    return !(result.length == 1 && result.first == ConnectivityResult.none);
  }

  /// True when [error] looks like DNS / socket / timeout / unreachable host.
  static bool looksLikeNetworkFailure(Object? error) {
    if (error == null) return false;
    final s = error.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('clientexception') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('network_error') ||
        s.contains('os error');
  }

  static String networkFailureMessage([
    String action = 'This action',
  ]) =>
      '$action needs a working internet connection. Check Wi‑Fi or mobile data and try again.';

  /// Returns true when online. Otherwise shows a snackbar (or dialog) and
  /// returns false — caller should abort the network operation.
  static Future<bool> ensureOnline(
    BuildContext context, {
    String message =
        'This needs an internet connection. Try again when you are online.',
    bool useDialog = false,
  }) async {
    if (await isOnline()) return true;
    if (!context.mounted) return false;

    if (useDialog) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No internet'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }
}
