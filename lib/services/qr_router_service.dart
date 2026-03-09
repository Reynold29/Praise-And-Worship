import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import './local_database_service.dart';
import '../widgets/app_config_provider.dart';
import '../screens/song_detail_screen.dart';
import '../utils/song_utils.dart';
import '../utils/app_logger.dart';

class QRRouterService {
  QRRouterService._();
  static final QRRouterService instance = QRRouterService._();

  // Cache for sorted song lists to speed up lookups
  final Map<String, List<Song>> _cachedSortedSongs = {};
  DateTime? _cacheTimestamp;

  /// Parses a URL and navigates to the corresponding song if valid.
  /// Format: https://projects.reyziehomelab.com/worshipcompanion/song?l=[lang]&i=[idx]
  Future<void> handleUrl(BuildContext context, String url) async {
    AppLogger.d('QRRouter', 'handleUrl received: $url');
    try {
      final uri = Uri.parse(url.trim());
      final config = Provider.of<AppConfigProvider>(context, listen: false);

      // 1. Validate Domain
      final host = uri.host.toLowerCase();
      AppLogger.d('QRRouter', 'Host: $host, Path: ${uri.path}');
      if (host.isNotEmpty && !config.whitelistedQrDomains.contains(host)) {
        AppLogger.w('QRRouter', 'Blocked non-whitelisted domain: $host');
        _showError(context, 'Invalid QR Code',
            'This QR code is not from a trusted source.');
        return;
      }

      // 2. Validate Path (Flexible)
      // Trim trailing slashes for robustness
      String cleanPath = uri.path.toLowerCase();
      while (cleanPath.endsWith('/')) {
        cleanPath = cleanPath.substring(0, cleanPath.length - 1);
      }

      if (!cleanPath.endsWith('/song')) {
        AppLogger.w('QRRouter', 'Invalid cleanPath: $cleanPath');
        return;
      }

      // 3. Extract Params
      final lang = uri.queryParameters['l']?.toLowerCase();
      final indexStr = uri.queryParameters['i'];
      if (lang == null || indexStr == null) {
        AppLogger.w('QRRouter', 'Missing params: l=$lang, i=$indexStr');
        return;
      }

      final index = int.tryParse(indexStr);
      if (index == null || index < 1) {
        AppLogger.w('QRRouter', 'Invalid index: $indexStr');
        return;
      }

      // 4. Fetch and Find Song (with Caching)
      _showLoading(context);

      // Invalidate cache if older than 5 minutes (to account for syncs)
      if (_cacheTimestamp == null ||
          DateTime.now().difference(_cacheTimestamp!).inMinutes > 5) {
        _cachedSortedSongs.clear();
      }

      List<Song> songs;
      if (_cachedSortedSongs.containsKey(lang)) {
        songs = _cachedSortedSongs[lang]!;
      } else {
        if (lang == 'english') {
          songs = await LocalDatabaseService.instance.fetchAllSongs();
        } else if (lang == 'kannada') {
          songs = await LocalDatabaseService.instance.fetchAllKannadaSongs();
        } else {
          songs = await LocalDatabaseService.instance.fetchAllOtherSongs();
        }

        // Sort alphabetically to match the 1-based index logic
        songs.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        _cachedSortedSongs[lang] = songs;
        _cacheTimestamp = DateTime.now();
      }

      if (context.mounted) Navigator.of(context).pop(); // hide loading

      if (index > songs.length) {
        _showError(context, 'Song Not Found',
            'The song index ($index) is out of range for $lang. Try syncing your library.');
        return;
      }

      final targetSong = songs[index - 1];

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongDetailScreen(
              tabData: {
                'id': targetSong.id,
                'category': targetSong.category,
                'title': targetSong.title,
                'artist_name': targetSong.authorName ?? '',
                'author': targetSong.authorName ?? '',
                'key_signature': targetSong.keySignature,
                'lines': SongUtils.parseLyricsToLines(
                    targetSong.lyrics, targetSong.chords),
                'trans_lines': targetSong.transLyrics != null &&
                        targetSong.transLyrics!.isNotEmpty
                    ? SongUtils.parseLyricsToLines(
                        targetSong.transLyrics!, targetSong.chords)
                    : null,
              },
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('QRRouter', 'Error handling QR URL', e);
      if (context.mounted) {
        // Ensure loading is hidden on error
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route is! DialogRoute);
        _showError(context, 'Error', 'Failed to process the QR code: $e');
      }
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Helper to get the 1-based index of a song in its language list.
  Future<int> getSongIndex(String lang, String songId) async {
    // Invalidate cache if older than 5 minutes
    if (_cacheTimestamp == null ||
        DateTime.now().difference(_cacheTimestamp!).inMinutes > 5) {
      _cachedSortedSongs.clear();
    }

    List<Song> songs;
    if (_cachedSortedSongs.containsKey(lang)) {
      songs = _cachedSortedSongs[lang]!;
    } else {
      if (lang == 'english') {
        songs = await LocalDatabaseService.instance.fetchAllSongs();
      } else if (lang == 'kannada') {
        songs = await LocalDatabaseService.instance.fetchAllKannadaSongs();
      } else {
        songs = await LocalDatabaseService.instance.fetchAllOtherSongs();
      }

      // Sort alphabetically to match the 1-based index logic
      songs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      _cachedSortedSongs[lang] = songs;
      _cacheTimestamp = DateTime.now();
    }

    return songs.indexWhere((s) => s.id.toString() == songId) + 1;
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
