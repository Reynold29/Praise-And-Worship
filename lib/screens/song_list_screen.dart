import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:vibration/vibration.dart';

class SongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;
  final VoidCallback? onFavoriteToggled;
  const SongListScreen({super.key, required this.heroTag, required this.cardImage, this.onFavoriteToggled});

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
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
        return song.title.isNotEmpty && song.title[0].toUpperCase() == _selectedLetter;
      }).toList();
    }
    _filteredSongs = filtered;
    _currentMax = _pageSize.clamp(0, _filteredSongs.length);
  }

  Future<void> _fetchSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchedSongs = await LocalDatabaseService.instance.fetchAllSongs();
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
      print("Error in SongListScreen: $e");
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
                  // gaplessPlayback: true,
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
          // Alphabet filter bar
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              children: [
                ..._alphabet.map((letter) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: ChoiceChip(
                    label: Text(letter),
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
                          'Loading your worship songs...',
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
                              'No songs found.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground
                                  ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _currentMax,
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredSongs.length) return null;
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