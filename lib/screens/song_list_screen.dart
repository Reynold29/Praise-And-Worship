import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:vibration/vibration.dart';

class SongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;
  final VoidCallback? onFavoriteToggled;
  const SongListScreen(
      {super.key,
      required this.heroTag,
      required this.cardImage,
      this.onFavoriteToggled});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String? _error;
  static const int _pageSize = 20;
  int _currentMax = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLetter;
  double _fontSize = 16;

  static const List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_currentMax < _songs.length) {
        setState(() {
          _currentMax = (_currentMax + _pageSize).clamp(0, _songs.length);
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterSongs();
    });
  }

  void _onLetterSelected(String? letter) {
    setState(() {
      _selectedLetter = letter;
      _filterSongs();
    });
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  void _filterSongs() {
    List<Song> filtered = List.from(_songs);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.authorName?.toLowerCase().contains(query) ?? false) ||
            song.lyrics.toLowerCase().contains(query);
      }).toList();
    }
    if (_selectedLetter != null && _selectedLetter!.isNotEmpty) {
      filtered = filtered.where((song) {
        return song.title.isNotEmpty &&
            song.title[0].toUpperCase() == _selectedLetter;
      }).toList();
    }
    _filteredSongs = filtered;
    _currentMax = _pageSize.clamp(0, _filteredSongs.length);
  }

  /// Letters that have at least one song in the current (pre-letter-filter) result set.
  Set<String> get _lettersWithSongs {
    final base = _searchQuery.isEmpty
        ? _songs
        : _songs.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                (s.authorName?.toLowerCase().contains(q) ?? false) ||
                s.lyrics.toLowerCase().contains(q);
          }).toList();
    return base
        .where((s) => s.title.isNotEmpty)
        .map((s) => s.title[0].toUpperCase())
        .toSet();
  }

  Future<void> _fetchSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Direct: fetch English songs from Supabase and show.
      final fetchedSongs =
          await SupabaseService.instance.getSongsByCategory('english_data');
      if (!mounted) return;
      setState(() {
        _songs = fetchedSongs;
        _filterSongs();
        _isLoading = false;
        _currentMax = _pageSize.clamp(0, _filteredSongs.length);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('App', 'Error in SongListScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableLetters = _lettersWithSongs;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Hero image + themed back button overlay
          Stack(
            children: [
              Hero(
                tag: widget.heroTag,
                transitionOnUserGestures: true,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/cards/${widget.cardImage}'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32)),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: Material(
                  color: colorScheme.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: colorScheme.shadow.withOpacity(0.4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Search bar and Font Controls
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Search songs…',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: colorScheme.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _performVibration();
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(180),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        tooltip: 'Decrease font size',
                        onPressed: () {
                          _performVibration();
                          setState(() {
                            if (_fontSize > 12) _fontSize -= 2;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          _fontSize.toInt().toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Increase font size',
                        onPressed: () {
                          _performVibration();
                          setState(() {
                            if (_fontSize < 28) _fontSize += 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sync Button Fallback
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  _performVibration();
                  setState(() => _isLoading = true);
                  try {
                    final fetched = await SupabaseService.instance
                        .getSongsByCategory('english_data');
                    if (!mounted) return;
                    setState(() {
                      _songs = fetched;
                      _filterSongs();
                      _currentMax = _pageSize.clamp(0, _filteredSongs.length);
                      _isLoading = false;
                    });
                  } catch (e) {
                    if (!mounted) return;
                    setState(() {
                      _error = 'Sync failed: $e';
                      _isLoading = false;
                    });
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text('Sync Songs',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(100),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          // Alphabet filter bar
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              children: [
                ..._alphabet.map((letter) {
                  final has = availableLetters.contains(letter);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Opacity(
                      opacity: has ? 1.0 : 0.3,
                      child: ChoiceChip(
                        label: Text(letter),
                        selected: _selectedLetter == letter,
                        onSelected: has
                            ? (_) {
                                _performVibration();
                                _onLetterSelected(
                                    _selectedLetter == letter ? null : letter);
                              }
                            : null,
                        selectedColor: colorScheme.primary.withOpacity(0.18),
                      ),
                    ),
                  );
                }),
                if (_selectedLetter != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ActionChip(
                      label: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _performVibration();
                        _onLetterSelected(null);
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          // Results count
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: (_searchQuery.isNotEmpty || _selectedLetter != null) &&
                    !_isLoading
                ? Padding(
                    key: ValueKey(_filteredSongs.length),
                    padding: const EdgeInsets.only(left: 20, top: 4, bottom: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_filteredSongs.length} song${_filteredSongs.length == 1 ? '' : 's'} found',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty-count')),
          ),
          // Song list body
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _isLoading
                  ? Center(
                      key: const ValueKey('loading'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          Text('Loading your worship songs…',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          key: const ValueKey('error'),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_error!,
                                style: TextStyle(color: colorScheme.error),
                                textAlign: TextAlign.center),
                          ),
                        )
                      : _filteredSongs.isEmpty
                          ? Center(
                              key: const ValueKey('empty'),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.music_off_rounded,
                                      size: 56,
                                      color: colorScheme.primary
                                          .withOpacity(0.25)),
                                  const SizedBox(height: 12),
                                  Text('No songs found.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('list'),
                              controller: _scrollController,
                              itemCount: _currentMax,
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 80.0),
                              itemBuilder: (context, index) {
                                if (index >= _filteredSongs.length) return null;
                                final song = _filteredSongs[index];
                                return SongCardWidget(
                                    song: song, fontSize: _fontSize);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
