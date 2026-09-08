import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_provider.dart';
import '../widgets/favorite_provider.dart';
import '../services/favorites_sync_service.dart';

/// Shows a dialog that lets the user merge local favourites into their cloud
/// account after signing in. Returns [true] if a sync was performed.
Future<bool?> showSyncDialog(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final favProv = Provider.of<FavoriteProvider>(context, listen: false);

  final localKeys =
      favProv.favoriteSongKeys.where((k) => k.isNotEmpty).toList();

  if (localKeys.isEmpty || !auth.isLoggedIn) return Future.value(false);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SyncDialog(
      localCount: localKeys.length,
      localKeys: localKeys,
      userId: auth.currentUser!.id,
    ),
  );
}

class _SyncDialog extends StatefulWidget {
  final int localCount;
  final List<String> localKeys;
  final String userId;

  const _SyncDialog({
    required this.localCount,
    required this.localKeys,
    required this.userId,
  });

  @override
  State<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<_SyncDialog> {
  bool _syncing = false;
  String? _statusMessage;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _statusMessage = 'Uploading your favourites…';
    });

    final favProv = Provider.of<FavoriteProvider>(context, listen: false);
    await FavoritesSyncService.instance
        .mergeLocalToCloud(widget.userId, widget.localKeys);

    // After cloud sync, reload cloud state into the provider
    await favProv.switchToCloud(widget.userId);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✔ Favourites synced to your account'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _syncBackground() {
    final favProv = Provider.of<FavoriteProvider>(context, listen: false);
    // Fire-and-forget
    () async {
      await FavoritesSyncService.instance
          .mergeLocalToCloud(widget.userId, widget.localKeys);
      await favProv.switchToCloud(widget.userId);
    }();

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing favourites in the background…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_upload_rounded,
                  color: cs.onPrimaryContainer, size: 30),
            ),
            const SizedBox(height: 20),

            Text('Sync Your Favourites',
                style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.onSurface),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'You have '),
                  TextSpan(
                    text:
                        '${widget.localCount} song${widget.localCount == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                      text:
                          ' saved locally. Merge them into your account so they\'re available on all your devices.'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_syncing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(_statusMessage ?? '',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ] else ...[
              // Sync Now
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sync Now'),
                  onPressed: _syncNow,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Run in Background
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text('Run in Background'),
                  onPressed: _syncBackground,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Skip
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Skip for now',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
