import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/playlist_provider.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
import 'package:worshipcompanion/screens/playlist_detail_screen.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProv = Provider.of<PlaylistProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playlists = playlistProv.playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music_rounded,
                      size: 64, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No playlists created yet',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create New Playlist'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final p = playlists[index];
                final songCount = playlistProv.getSongsInPlaylist(p.id).length;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.playlist_play_rounded,
                            color: colorScheme.onPrimaryContainer, size: 32),
                      ),
                      title: Text(p.name,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('$songCount songs',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          snappyPageRoute(
                              page: PlaylistDetailScreen(playlist: p)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: playlists.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Playlist'),
            )
          : null,
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final playlistProv = Provider.of<PlaylistProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Sunday Service',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  await playlistProv.createPlaylist(name);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (e.toString().contains('LIMIT_REACHED')) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showLimitReachedDialog(context);
                    }
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist Limit'),
        content: const Text(
            'Unregistered users can create up to 3 playlists. Please sign in or create an account to create unlimited playlists!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Open Settings or Profile page logic
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
