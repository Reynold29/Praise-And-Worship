import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/models/playlist_model.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/widgets/playlist_provider.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:worshipcompanion/widgets/share_qr_dialog.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final playlistProv = Provider.of<PlaylistProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final songs = playlistProv.getSongsInPlaylist(playlist.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => _showQRShareDialog(context),
            tooltip: 'Share Playlist',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDeletePlaylist(context),
            tooltip: 'Delete Playlist',
          ),
        ],
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note_rounded,
                      size: 64, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No songs in this playlist',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final ps = songs[index];
                return FutureBuilder<Song?>(
                  future: _fetchSongDetails(ps.songId, ps.category),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Loading...',
                            style: TextStyle(color: colorScheme.outline)),
                      );
                    }

                    final song = snapshot.data;
                    if (song == null) {
                      return ListTile(
                        leading:
                            Icon(Icons.error_outline, color: colorScheme.error),
                        title: Text('Song not found',
                            style: TextStyle(color: colorScheme.error)),
                        subtitle: Text('ID: ${ps.songId}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => playlistProv.removeSongFromPlaylist(
                              playlist.id, ps.id),
                        ),
                      );
                    }

                    final displayTitle = (song.englishTitle != null &&
                            song.englishTitle!.isNotEmpty)
                        ? song.englishTitle!
                        : song.title;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      title: Text(
                        displayTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.authorName ?? 'Unknown Artist',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) {
                          if (value == 'remove') {
                            playlistProv.removeSongFromPlaylist(
                                playlist.id, ps.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.remove_circle_outline_rounded,
                                    size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Remove',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          snappyPageRoute(
                            page: SongDetailScreen(
                              tabData: {
                                'id': song.id,
                                'category': song.category,
                                'title': displayTitle,
                                'original_title': song.title,
                                'english_title': song.englishTitle,
                                'artist_name': song.authorName ?? '',
                                'author': song.authorName ?? '',
                                'author_name': song.authorName ?? '',
                                'key_signature': song.keySignature,
                                'youtube_link': song.youtubeLink,
                                'lyrics': song.lyrics,
                                'trans_lyrics': song.transLyrics,
                                'chords': song.chords,
                                'genre': song.genre,
                                'bpm': song.bpm,
                                'raw_lyrics': song.lyrics,
                                'raw_trans_lyrics': song.transLyrics,
                                'raw_chords': song.chords,
                                'lines': SongUtils.parseLyricsToLines(
                                    song.lyrics, song.chords),
                                'trans_lines': song.transLyrics != null &&
                                        song.transLyrics!.isNotEmpty
                                    ? SongUtils.parseLyricsToLines(
                                        song.transLyrics!, song.chords)
                                    : null,
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<Song?> _fetchSongDetails(String id, String category) async {
    final db = LocalDatabaseService.instance;
    final table = category.endsWith('_data') ? category : '${category}_data';
    final data = await db.getSongById(table, id);
    if (data == null) return null;
    return Song.fromJson(data);
  }

  void _showQRShareDialog(BuildContext context) {
    final config = Provider.of<AppConfigProvider>(context, listen: false);
    showShareQrDialog(
      context: context,
      heading: 'Share Playlist',
      subtitle: 'Anyone can scan this to import this playlist',
      qrUrl: '${config.qrBaseUrl}/playlist?id=${playlist.id}',
      caption: playlist.name,
    );
  }

  void _confirmDeletePlaylist(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Provider.of<PlaylistProvider>(context, listen: false)
                  .deletePlaylist(playlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from detail screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
