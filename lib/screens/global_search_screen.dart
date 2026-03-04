import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart';
import 'package:vibration/vibration.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = [];
  List<Song> _searchResults = [];
  bool _isLoading = true;
  String _filterLang = 'All';
  String _sortOrder = 'A-Z';

  @override
  void initState() {
    super.initState();
    _fetchAllSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSongs() async {
    setState(() => _isLoading = true);
    try {
      final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
      final allKannada = await LocalDatabaseService.instance.fetchAllKannadaSongs();
      if (mounted) {
        setState(() {
          _allSongs = [...allEnglish, ...allKannada];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching songs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty && _filterLang == 'All' && _sortOrder == 'A-Z') {
      setState(() => _searchResults = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    List<Song> results = _allSongs.where((s) {
      // Language Filter
      if (_filterLang == 'English' && !_isEnglish(s)) return false;
      if (_filterLang == 'Kannada' && !_isKannada(s)) return false;

      // Text Search
      if (lowerQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(lowerQuery) ||
             (s.authorName?.toLowerCase().contains(lowerQuery) ?? false) ||
             s.lyrics.toLowerCase().contains(lowerQuery);
    }).toList();

    // Sorting
    if (_sortOrder == 'A-Z') {
      results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortOrder == 'Z-A') {
      results.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (_sortOrder == 'Recently Added') {
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() {
      _searchResults = results;
    });
  }

  bool _isEnglish(Song s) {
    final cat = s.category.trim().toLowerCase();
    return cat == 'english_data' || cat == 'english';
  }

  bool _isKannada(Song s) {
    final cat = s.category.trim().toLowerCase();
    return cat == 'kannada_data' || cat == 'kannada';
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  // Helper to convert song to lines for detail screen
  static List<Map<String, dynamic>> _convertSongToLines(Song song) {
    final lyricLines = song.lyrics.split('\n');
    final chordLines = (song.chords ?? '').split('\n');
    final lines = <Map<String, dynamic>>[];
    for (int i = 0; i < lyricLines.length; i++) {
      if (i < chordLines.length && chordLines[i].trim().isNotEmpty) {
        lines.add({'type': 'chords', 'chords': _parseChordsLineStatic(chordLines[i])});
      }
      lines.add({'type': 'lyric', 'lyric': lyricLines[i]});
    }
    return lines;
  }

  static List<Map<String, dynamic>> _parseChordsLineStatic(String chordLine) {
    final chords = <Map<String, dynamic>>[];
    final regex = RegExp(r'\S+');
    for (final match in regex.allMatches(chordLine)) {
      chords.add({
        'note': match.group(0),
        'pre_spaces': match.start,
      });
    }
    return chords;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Hero(
      tag: 'global_search_hero',
      createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
      child: Scaffold(
        backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search songs, lyrics, authors...',
            hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: colorScheme.onSurface),
            onPressed: () {
              _performVibration();
              _showFilterBottomSheet(context);
            },
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded, color: colorScheme.onSurface),
              onPressed: () {
                _performVibration();
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty && _searchController.text.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No songs found',
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty && _searchController.text.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Type to search',
                            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final song = _searchResults[index];
                        return ListTile(
                          title: Text(
                            song.title,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            song.authorName ?? 'Unknown Author',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              song.title.isNotEmpty ? song.title[0].toUpperCase() : '?',
                              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            _performVibration();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongDetailScreen(
                                  tabData: {
                                    'id': song.id,
                                    'category': song.category,
                                    'title': song.title,
                                    'artist_name': song.authorName ?? '',
                                    'author': song.authorName ?? '',
                                    'key_signature': song.keySignature,
                                    'lines': _convertSongToLines(song),
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by Language', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'English', 'Kannada'].map((lang) {
                      final isSelected = _filterLang == lang;
                      return FilterChip(
                        label: Text(lang),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterLang = lang);
                            setModalState(() {});
                            _performSearch(_searchController.text);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Sort Order', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['A-Z', 'Z-A', 'Recently Added'].map((sort) {
                      final isSelected = _sortOrder == sort;
                      return FilterChip(
                        label: Text(sort),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortOrder = sort);
                            setModalState(() {});
                            _performSearch(_searchController.text);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
