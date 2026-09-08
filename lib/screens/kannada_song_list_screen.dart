import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:worshipcompanion/widgets/language_card_hero.dart';
import 'package:worshipcompanion/widgets/song_list_controls.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:inditrans/inditrans.dart' as inditrans;
import 'package:vibration/vibration.dart';

class KannadaSongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;
  final VoidCallback? onFavoriteToggled;
  const KannadaSongListScreen(
      {super.key,
      required this.heroTag,
      required this.cardImage,
      this.onFavoriteToggled});

  @override
  State<KannadaSongListScreen> createState() => _KannadaSongListScreenState();
}

class _KannadaSongListScreenState extends State<KannadaSongListScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Ensure search controller is properly initialized
  void _initializeSearchController() {
    _searchController.clear();
    _searchQuery = '';
  }

  String? _selectedLetter;
  double _fontSize = 16;
  bool _showEnglishTitle = true;
  List<String> _availableAlphabet = [];

  // Main Kannada vowels and consonants for filtering (can be expanded)
  static const List<String> _kannadaAlphabet = [
    'ಅ',
    'ಆ',
    'ಇ',
    'ಈ',
    'ಉ',
    'ಊ',
    'ಋ',
    'ಎ',
    'ಏ',
    'ಐ',
    'ಒ',
    'ಓ',
    'ಔ',
    'ಕ',
    'ಖ',
    'ಗ',
    'ಘ',
    'ಚ',
    'ಛ',
    'ಜ',
    'ಝ',
    'ಟ',
    'ಠ',
    'ಡ',
    'ಢ',
    'ತ',
    'ಥ',
    'ದ',
    'ಧ',
    'ನ',
    'ಪ',
    'ಫ',
    'ಬ',
    'ಭ',
    'ಮ',
    'ಯ',
    'ರ',
    'ಲ',
    'ವ',
    'ಶ',
    'ಷ',
    'ಸ',
    'ಹ',
    'ಳ',
    'ಕ್ಷ',
    'ಜ್ಞ'
  ];

  // Generate available alphabet based on actual songs
  void _generateAvailableAlphabet() {
    final Set<String> availableLetters = <String>{};

    for (final song in _songs) {
      if (song.title.isNotEmpty) {
        final firstChar = song.title[0];
        if (_kannadaAlphabet.contains(firstChar)) {
          availableLetters.add(firstChar);
        }
      }
    }

    // Sort the available letters according to the original alphabet order
    _availableAlphabet = _kannadaAlphabet
        .where((letter) => availableLetters.contains(letter))
        .toList();

    // Clear selected letter if it's no longer available
    if (_selectedLetter != null &&
        !_availableAlphabet.contains(_selectedLetter)) {
      _selectedLetter = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSearchController();
    _searchController.addListener(_onSearchChanged);
    _initAndFetch();

    // Add a post-frame callback to ensure search is cleared
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSearchController();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear any cached text when dependencies change
    _initializeSearchController();
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
      final kannadaQuery = inditrans.transliterate(
          query, inditrans.Script.itrans, inditrans.Script.kannada);
      filtered = _songs
          .asMap()
          .entries
          .where((entry) {
            final song = entry.value;
            final indexStr = (entry.key + 1).toString();
            return indexStr.contains(query) ||
                song.title.toLowerCase().contains(query) ||
                song.title.contains(kannadaQuery) ||
                (song.englishTitle?.toLowerCase().contains(query) ?? false) ||
                (song.authorName?.toLowerCase().contains(query) ?? false) ||
                (song.authorName?.contains(kannadaQuery) ?? false);
          })
          .map((e) => e.value)
          .toList();
    }
    if (_selectedLetter != null && _selectedLetter!.isNotEmpty) {
      filtered = filtered.where((song) {
        return song.title.isNotEmpty && song.title[0] == _selectedLetter;
      }).toList();

      // If no songs found for selected letter, clear the selection
      if (filtered.isEmpty) {
        _selectedLetter = null;
      }
    }
    _filteredSongs = filtered;
  }

  Future<void> _initAndFetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchedSongs =
          await LocalDatabaseService.instance.fetchAllKannadaSongs();
      if (mounted) {
        final filtered = _filterInvalidSongs(fetchedSongs);

        filtered.sort((a, b) {
          final aTitle = (a.englishTitle != null && a.englishTitle!.isNotEmpty)
              ? a.englishTitle!
              : a.title;
          final bTitle = (b.englishTitle != null && b.englishTitle!.isNotEmpty)
              ? b.englishTitle!
              : b.title;
          return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
        });

        setState(() {
          _songs = filtered;
          _generateAvailableAlphabet();
          _filterSongs();
          _isLoading = false;
        });
      }

      if (await ConnectivityGuard.isOnline()) {
        LocalDatabaseService.instance.syncKannadaFromSupabase().then((_) async {
          final refreshed = await LocalDatabaseService.instance
              .fetchAllKannadaSongs(allowNetwork: false);
          if (!mounted || refreshed.isEmpty) return;
          final filtered = _filterInvalidSongs(refreshed);
          filtered.sort((a, b) {
            final aTitle =
                (a.englishTitle != null && a.englishTitle!.isNotEmpty)
                    ? a.englishTitle!
                    : a.title;
            final bTitle =
                (b.englishTitle != null && b.englishTitle!.isNotEmpty)
                    ? b.englishTitle!
                    : b.title;
            return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
          });
          setState(() {
            _songs = filtered;
            _generateAvailableAlphabet();
            _filterSongs();
          });
        }).catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('KannadaList', 'Error loading Kannada songs', e);
    }
  }

  List<Song> _filterInvalidSongs(List<Song> songs) {
    return songs.where((song) {
      final title = song.title.toLowerCase();
      return !title.contains('search christian lyrics') &&
          !title.contains('search christian') &&
          !title.contains('christian lyrics');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor:
                      Theme.of(context).colorScheme.shadow.withOpacity(0.4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SongListControlsBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            searchHint: 'Search songs…',
            fontSize: _fontSize,
            onFontSizeChanged: (v) => setState(() => _fontSize = v),
            syncLabel: 'Sync',
            onSync: () async {
              _performVibration();
              if (!await ConnectivityGuard.ensureOnline(context,
                  message:
                      'Sync needs internet to download the latest Kannada songs.')) {
                return;
              }
              setState(() => _isLoading = true);
              try {
                await LocalDatabaseService.instance.syncKannadaFromSupabase(
                    forceFullResync: true, throwOnError: true);
                await LocalDatabaseService.instance.removeUnwantedKannadaSongs();
                final fetched = await LocalDatabaseService.instance
                    .fetchAllKannadaSongs(allowNetwork: false);
                if (!mounted) return;
                final filtered = _filterInvalidSongs(fetched);
                filtered.sort((a, b) {
                  final aTitle =
                      (a.englishTitle != null && a.englishTitle!.isNotEmpty)
                          ? a.englishTitle!
                          : a.title;
                  final bTitle =
                      (b.englishTitle != null && b.englishTitle!.isNotEmpty)
                          ? b.englishTitle!
                          : b.title;
                  return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
                });
                setState(() {
                  _songs = filtered;
                  _generateAvailableAlphabet();
                  _filterSongs();
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleLanguageChip(
                  context: context,
                  label: 'English',
                  isSelected: _showEnglishTitle,
                  onTap: () {
                    if (!_showEnglishTitle) {
                      _performVibration();
                      setState(() => _showEnglishTitle = true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildTitleLanguageChip(
                  context: context,
                  label: 'Kannada',
                  isSelected: !_showEnglishTitle,
                  onTap: () {
                    if (_showEnglishTitle) {
                      _performVibration();
                      setState(() => _showEnglishTitle = false);
                    }
                  },
                ),
              ],
            ),
          ),
          SongListAlphabetBar(
            letters: _kannadaAlphabet,
            availableLetters: _availableAlphabet.toSet(),
            selectedLetter: _selectedLetter,
            onSelected: _onLetterSelected,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Loading Kannada worship songs...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredSongs.isEmpty
                        ? Center(
                            child: Text(
                              'No Kannada songs found.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredSongs.length,
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            itemBuilder: (context, index) {
                              final song = _filteredSongs[index];
                              final originalIndex = _songs.indexOf(song) + 1;
                              return SongCardWidget(
                                song: song,
                                fontSize: _fontSize,
                                showEnglishTitle: _showEnglishTitle,
                                displayIndex: originalIndex,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleLanguageChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.6)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(0, 40),
          splashFactory: InkSparkle.splashFactory,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
