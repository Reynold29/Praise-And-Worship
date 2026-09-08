import 'package:material_ui/material_ui.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/screens/language_song_list_screen.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:flutter/services.dart';
import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:worshipcompanion/widgets/language_card_hero.dart';
import 'package:worshipcompanion/widgets/song_list_controls.dart';

class OtherSongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;

  const OtherSongListScreen(
      {Key? key, required this.heroTag, required this.cardImage});

  @override
  _OtherSongListScreenState createState() => _OtherSongListScreenState();
}

class _OtherSongListScreenState extends State<OtherSongListScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<String> _availableCategories = ['All'];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All'; // New filter state
  double _fontSize = 16;

  void _initializeSearchController() {
    _searchController.clear();
    _searchQuery = '';
  }

  @override
  void initState() {
    super.initState();
    _initializeSearchController();
    _searchController.addListener(_onSearchChanged);
    _initAndFetch();

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
    _initializeSearchController();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterSongs();
    });
  }

  void _performVibration() {
    HapticFeedback.lightImpact();
  }

  void _filterSongs() {
    List<Song> filtered = List.from(_songs);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.englishTitle?.toLowerCase().contains(query) ?? false) ||
            (song.authorName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((song) => song.category == _selectedCategory).toList();
    }
    setState(() {
      _filteredSongs = filtered;
    });
  }

  Future<void> _initAndFetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final songs = await LocalDatabaseService.instance.fetchAllOtherSongs();
      if (!mounted) return;
      _applyOtherSongs(songs);

      if (await ConnectivityGuard.isOnline()) {
        LocalDatabaseService.instance.syncOtherFromSupabase().then((_) async {
          final refreshed = await LocalDatabaseService.instance
              .fetchAllOtherSongs(allowNetwork: false);
          if (!mounted || refreshed.isEmpty) return;
          _applyOtherSongs(refreshed);
        }).catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.e('OtherList', 'Error loading other songs', e);
    }
  }

  void _applyOtherSongs(List<Song> songs) {
    final uniqueCategories = songs
        .map((s) => s.category)
        .where((c) => c != 'unknown_data' && c.isNotEmpty)
        .toSet()
        .toList();
    uniqueCategories.sort();

    songs.sort((a, b) {
      final aTitle = (a.englishTitle != null && a.englishTitle!.isNotEmpty)
          ? a.englishTitle!
          : a.title;
      final bTitle = (b.englishTitle != null && b.englishTitle!.isNotEmpty)
          ? b.englishTitle!
          : b.title;
      return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
    });

    setState(() {
      _songs = songs;
      _availableCategories = ['All', ...uniqueCategories];

      if (!_availableCategories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }

      _filterSongs();
      _isLoading = false;
    });
  }

  void _navigateToLanguage(String category) {
    List<Song> categorySongs = category == 'All'
        ? _filteredSongs
        : _filteredSongs.where((s) => s.category == category).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageSongListScreen(
          categoryName:
              category == 'All' ? 'All Songs' : _formatCategoryName(category),
          songs: categorySongs,
          heroTag: '${widget.heroTag}_$category',
          cardImage: widget.cardImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate 'All' from the specific languages for layout
    final languages = _availableCategories.where((c) => c != 'All').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
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
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/cards/${widget.cardImage}',
                            fit: BoxFit.cover,
                            cacheWidth:
                                LanguageCardHero.cacheWidthFor(context),
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 20, bottom: 20),
                            child: Text(
                              'Other Languages',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4.0,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    onTap: () {
                      _performVibration();
                      Navigator.of(context).pop();
                    },
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
            searchHint: 'Search songs across all languages…',
            fontSize: _fontSize,
            onFontSizeChanged: (v) => setState(() => _fontSize = v),
            syncLabel: 'Sync',
            onSync: () async {
              _performVibration();
              if (!await ConnectivityGuard.ensureOnline(context,
                  message:
                      'Sync needs internet to download the latest songs.')) {
                return;
              }
              setState(() => _isLoading = true);
              try {
                await LocalDatabaseService.instance.syncOtherFromSupabase(
                    forceFullResync: true, throwOnError: true);
                final fetched = await LocalDatabaseService.instance
                    .fetchAllOtherSongs(allowNetwork: false);
                if (!mounted) return;
                _applyOtherSongs(fetched);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            },
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- 'All Songs' Card ---
                  _buildCategoryCard('All', 'All Songs', Icons.library_music),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Select Language',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Grid of Specific Languages ---
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final category = languages[index];
                      return _buildCategoryCard(category,
                          _formatCategoryName(category), Icons.language);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String categoryKey, String displayName, IconData iconData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _performVibration();
          _navigateToLanguage(categoryKey);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconData,
                    size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    if (category.isEmpty) return category;
    return "${category[0].toUpperCase()}${category.substring(1)}";
  }
}
