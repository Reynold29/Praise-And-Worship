import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:worshipcompanion/widgets/language_card_hero.dart';
import 'package:worshipcompanion/widgets/song_list_controls.dart';
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
      filtered = _songs
          .asMap()
          .entries
          .where((entry) {
            final song = entry.value;
            final indexStr = (entry.key + 1).toString();
            return indexStr.contains(query) ||
                song.title.toLowerCase().contains(query) ||
                (song.englishTitle?.toLowerCase().contains(query) ?? false) ||
                (song.authorName?.toLowerCase().contains(query) ?? false);
          })
          .map((e) => e.value)
          .toList();
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
        : _songs
            .asMap()
            .entries
            .where((entry) {
              final s = entry.value;
              final indexStr = (entry.key + 1).toString();
              final q = _searchQuery.toLowerCase();
              return indexStr.contains(q) ||
                  s.title.toLowerCase().contains(q) ||
                  (s.englishTitle?.toLowerCase().contains(q) ?? false) ||
                  (s.authorName?.toLowerCase().contains(q) ?? false);
            })
            .map((e) => e.value)
            .toList();
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
      final fetchedSongs =
          await LocalDatabaseService.instance.fetchAllSongs();
      if (!mounted) return;

      fetchedSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      setState(() {
        _songs = fetchedSongs;
        _filterSongs();
        _isLoading = false;
        _currentMax = _pageSize.clamp(0, _filteredSongs.length);
      });

      // Quiet background refresh when online (does not block UI).
      if (await ConnectivityGuard.isOnline()) {
        LocalDatabaseService.instance.syncFromSupabase().then((_) async {
          final refreshed =
              await LocalDatabaseService.instance.fetchAllSongs(allowNetwork: false);
          if (!mounted || refreshed.isEmpty) return;
          refreshed.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          setState(() {
            _songs = refreshed;
            _filterSongs();
            _currentMax = _pageSize.clamp(0, _filteredSongs.length);
          });
        }).catchError((_) {});
      }
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
                createRectTween: LanguageCardHero.createRectTween,
                placeholderBuilder: LanguageCardHero.placeholderBuilder,
                flightShuttleBuilder:
                    (context, animation, direction, fromHero, toHero) {
                  return LanguageCardHero.flightShuttle(
                    animation: animation,
                    direction: direction,
                    imageName: widget.cardImage,
                    cacheWidth: LanguageCardHero.cacheWidthFor(context),
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32)),
                    child: Image.asset(
                      'assets/cards/${widget.cardImage}',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: LanguageCardHero.cacheWidthFor(context),
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
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
          // Search + font (M3E) + sync
          SongListControlsBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            searchHint: 'Search songs…',
            fontSize: _fontSize,
            onFontSizeChanged: (v) => setState(() => _fontSize = v),
            syncLabel: 'Sync Songs',
            onSync: () async {
              _performVibration();
              if (!await ConnectivityGuard.ensureOnline(context,
                  message:
                      'Sync needs internet to download the latest English songs.')) {
                return;
              }
              setState(() => _isLoading = true);
              try {
                await LocalDatabaseService.instance
                    .syncFromSupabase(forceFullResync: true, throwOnError: true);
                final fetched = await LocalDatabaseService.instance
                    .fetchAllSongs(allowNetwork: false);
                if (!mounted) return;
                fetched.sort((a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                setState(() {
                  _songs = fetched;
                  _filterSongs();
                  _currentMax = _pageSize.clamp(0, _filteredSongs.length);
                  _isLoading = false;
                });
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            },
          ),
          SongListAlphabetBar(
            letters: _alphabet,
            availableLetters: availableLetters,
            selectedLetter: _selectedLetter,
            onSelected: _onLetterSelected,
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
                                final originalIndex = _songs.indexOf(song) + 1;
                                return SongCardWidget(
                                    song: song,
                                    fontSize: _fontSize,
                                    displayIndex: originalIndex);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
