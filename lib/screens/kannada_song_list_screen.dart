import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:inditrans/inditrans.dart' as inditrans;
import 'package:vibration/vibration.dart';

class KannadaSongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;
  final VoidCallback? onFavoriteToggled;
  const KannadaSongListScreen({super.key, required this.heroTag, required this.cardImage, this.onFavoriteToggled});

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
  List<String> _availableAlphabet = [];

  // Main Kannada vowels and consonants for filtering (can be expanded)
  static const List<String> _kannadaAlphabet = [
    'ಅ', 'ಆ', 'ಇ', 'ಈ', 'ಉ', 'ಊ', 'ಋ', 'ಎ', 'ಏ', 'ಐ', 'ಒ', 'ಓ', 'ಔ',
    'ಕ', 'ಖ', 'ಗ', 'ಘ', 'ಚ', 'ಛ', 'ಜ', 'ಝ', 'ಟ', 'ಠ', 'ಡ', 'ಢ', 'ತ', 'ಥ', 'ದ', 'ಧ', 'ನ',
    'ಪ', 'ಫ', 'ಬ', 'ಭ', 'ಮ', 'ಯ', 'ರ', 'ಲ', 'ವ', 'ಶ', 'ಷ', 'ಸ', 'ಹ', 'ಳ', 'ಕ್ಷ', 'ಜ್ಞ'
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
    if (_selectedLetter != null && !_availableAlphabet.contains(_selectedLetter)) {
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
      final kannadaQuery = inditrans.transliterate(query, inditrans.Script.itrans, inditrans.Script.kannada);
      filtered = filtered.where((song) {
        return song.title.toLowerCase().contains(query) ||
               song.title.contains(kannadaQuery) ||
               (song.authorName?.toLowerCase().contains(query) ?? false) ||
               (song.authorName?.contains(kannadaQuery) ?? false) ||
               song.lyrics.toLowerCase().contains(query) ||
               song.lyrics.contains(kannadaQuery);
      }).toList();
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
      // First, remove any unwanted songs from the database
      await LocalDatabaseService.instance.removeUnwantedKannadaSongs();
      
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await LocalDatabaseService.instance.syncKannadaFromSupabase();
      }
      final fetchedSongs = await LocalDatabaseService.instance.fetchAllKannadaSongs();
      if (!mounted) return;
      
      // Filter out any unwanted songs that might still exist
      final filteredSongs = fetchedSongs.where((song) {
        final title = song.title.toLowerCase();
        return !title.contains('search christian lyrics') && 
               !title.contains('search christian') &&
               !title.contains('christian lyrics');
      }).toList();
      
      setState(() {
        _songs = filteredSongs;
        _generateAvailableAlphabet(); // Generate available alphabet based on actual songs
        _filterSongs();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print("Error in KannadaSongListScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Hero(
            tag: widget.heroTag,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/cards/${widget.cardImage}'),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onTap: () {
                      // Clear any unwanted cached text when user taps the search field
                      if (_searchController.text.contains('christian') || _searchController.text.contains('lyrics')) {
                        _searchController.clear();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _performVibration();
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withAlpha(80),
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
                        icon: Icon(Icons.remove, size: 20),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 20),
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
          // Kannada alphabet filter bar
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              children: [
                ..._availableAlphabet.map((letter) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: ChoiceChip(
                    label: Text(letter, style: TextStyle(fontSize: 18)),
                    selected: _selectedLetter == letter,
                    onSelected: (_) {
                      _performVibration();
                      _onLetterSelected(_selectedLetter == letter ? null : letter);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                  ),
                )),
                if (_selectedLetter != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ActionChip(
                      label: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _performVibration();
                        _onLetterSelected(null);
                      },
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
              ],
            ),
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
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredSongs.isEmpty
                        ? Center(
                            child: Text(
                              'No Kannada songs found.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredSongs.length,
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            itemBuilder: (context, index) {
                              final song = _filteredSongs[index];
                              return SongCardWidget(song: song, fontSize: _fontSize);
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 