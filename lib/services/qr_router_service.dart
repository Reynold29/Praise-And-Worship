import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import './local_database_service.dart';
import './playlists_sync_service.dart';
import '../widgets/app_config_provider.dart';
import '../widgets/playlist_provider.dart';
import '../screens/song_detail_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../utils/song_utils.dart';
import '../utils/app_logger.dart';

class QRRouterService {
  QRRouterService._();
  static final QRRouterService instance = QRRouterService._();

  final Map<String, List<Song>> _cachedSortedSongs = {};
  DateTime? _cacheTimestamp;

  /// Handles song (`/lyrics`, legacy `/song`) and playlist (`/playlist`) URLs.
  Future<void> handleUrl(BuildContext context, String url) async {
    AppLogger.d('QRRouter', 'handleUrl received: $url');
    try {
      final uri = Uri.parse(url.trim());
      if (uri.scheme == 'io.supabase.worshipcompanion' ||
          uri.host.toLowerCase() == 'login-callback') {
        AppLogger.d('QRRouter', 'Ignoring OAuth callback');
        return;
      }

      // Custom scheme from web "Open In App" (esp. iOS without Universal Links).
      // worshipcompanion://lyrics?l=&id=  /  worshipcompanion://playlist?id=
      if (uri.scheme == 'worshipcompanion') {
        final host = uri.host.toLowerCase();
        AppLogger.d('QRRouter', 'Custom scheme host=$host query=${uri.query}');
        if (host == 'playlist') {
          await _openPlaylist(context, uri);
          return;
        }
        if (host == 'lyrics' || host == 'song') {
          await _openSong(context, uri);
          return;
        }
        AppLogger.w('QRRouter', 'Unknown worshipcompanion host: $host');
        return;
      }

      final config = Provider.of<AppConfigProvider>(context, listen: false);

      final host = uri.host.toLowerCase();
      AppLogger.d('QRRouter', 'Host: $host, Path: ${uri.path}');
      if (host.isNotEmpty && !config.whitelistedQrDomains.contains(host)) {
        AppLogger.w('QRRouter', 'Blocked non-whitelisted domain: $host');
        _showError(context, 'Invalid QR Code',
            'This QR code is not from a trusted source.');
        return;
      }

      String cleanPath = uri.path.toLowerCase();
      while (cleanPath.endsWith('/')) {
        cleanPath = cleanPath.substring(0, cleanPath.length - 1);
      }

      if (cleanPath.endsWith('/playlist')) {
        await _openPlaylist(context, uri);
        return;
      }

      if (cleanPath.endsWith('/lyrics') || cleanPath.endsWith('/song')) {
        await _openSong(context, uri);
        return;
      }

      AppLogger.w('QRRouter', 'Invalid cleanPath: $cleanPath');
    } catch (e) {
      AppLogger.e('QRRouter', 'Error handling QR URL', e);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route is! DialogRoute);
        _showError(context, 'Error', 'Failed to process the QR code: $e');
      }
    }
  }

  Future<void> _openPlaylist(BuildContext context, Uri uri) async {
    final playlistId = uri.queryParameters['id'];
    if (playlistId == null || playlistId.isEmpty) {
      _showError(context, 'Invalid QR', 'This playlist link is missing an id.');
      return;
    }

    _showLoading(context);
    try {
      final playlistProv =
          Provider.of<PlaylistProvider>(context, listen: false);
      final existing = playlistProv.playlists
          .where((p) => p.id == playlistId)
          .toList();

      if (existing.isNotEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlist: existing.first),
          ),
        );
        return;
      }

      final remote =
          await PlaylistsSyncService.instance.fetchPlaylistById(playlistId);
      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;

      if (remote == null) {
        _showError(context, 'Playlist Not Found',
            'This playlist is not available in the cloud. Sign-in playlists can be viewed on the web and imported here.');
        return;
      }

      final songs = await PlaylistsSyncService.instance
          .fetchPlaylistSongsById(playlistId);
      final imported =
          await playlistProv.importPlaylist(remote.name, songs);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: imported),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route is! DialogRoute);
        _showError(context, 'Import failed', e.toString());
      }
    }
  }

  Future<void> _openSong(BuildContext context, Uri uri) async {
    final lang = uri.queryParameters['l']?.toLowerCase();
    final songId = uri.queryParameters['id'];
    final indexStr = uri.queryParameters['i'];

    _showLoading(context);

    Song? targetSong;
    if (songId != null && songId.isNotEmpty && lang != null) {
      targetSong =
          await LocalDatabaseService.instance.fetchSongById(lang, songId);
    } else if (lang != null && indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 1) {
        final songs = await _sortedSongs(lang);
        if (index <= songs.length) {
          targetSong = songs[index - 1];
        }
      }
    }

    if (context.mounted) Navigator.of(context).pop();

    if (targetSong == null) {
      if (context.mounted) {
        _showError(context, 'Song Not Found',
            'Could not find this song. Try syncing your library.');
      }
      return;
    }

    if (!context.mounted) return;
    final song = targetSong;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongDetailScreen(
          tabData: {
            'id': song.id,
            'category': song.category,
            'title': song.title,
            'english_title': song.englishTitle,
            'artist_name': song.authorName ?? '',
            'author': song.authorName ?? '',
            'key_signature': song.keySignature,
            'youtube_link': song.youtubeLink,
            'lines':
                SongUtils.parseLyricsToLines(song.lyrics, song.chords),
            'trans_lines': song.transLyrics != null &&
                    song.transLyrics!.isNotEmpty
                ? SongUtils.parseLyricsToLines(
                    song.transLyrics!, song.chords)
                : null,
          },
        ),
      ),
    );
  }

  Future<List<Song>> _sortedSongs(String lang) async {
    if (_cacheTimestamp == null ||
        DateTime.now().difference(_cacheTimestamp!).inMinutes > 5) {
      _cachedSortedSongs.clear();
    }

    if (_cachedSortedSongs.containsKey(lang)) {
      return _cachedSortedSongs[lang]!;
    }

    List<Song> songs;
    if (lang == 'english') {
      songs = await LocalDatabaseService.instance.fetchAllSongs();
    } else if (lang == 'kannada') {
      songs = await LocalDatabaseService.instance.fetchAllKannadaSongs();
    } else {
      songs = await LocalDatabaseService.instance.fetchAllOtherSongs();
    }

    songs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    _cachedSortedSongs[lang] = songs;
    _cacheTimestamp = DateTime.now();
    return songs;
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
