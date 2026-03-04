import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:vibration/vibration.dart';

class LanguageSongListScreen extends StatefulWidget {
  final String categoryName;
  final List<Song> songs;
  final String heroTag;
  final String cardImage;

  const LanguageSongListScreen({
    Key? key,
    required this.categoryName,
    required this.songs,
    required this.heroTag,
    required this.cardImage,
  }) : super(key: key);

  @override
  _LanguageSongListScreenState createState() => _LanguageSongListScreenState();
}

class _LanguageSongListScreenState extends State<LanguageSongListScreen> {
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _fontSize = 16;
  bool _showEnglishTitle = true;

  @override
  void initState() {
    super.initState();
    _filteredSongs = widget.songs;
    _initializeSearchController();
  }

  void _initializeSearchController() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterSongs();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 50);
    }
  }

  void _filterSongs() {
    List<Song> filtered = widget.songs;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.englishTitle?.toLowerCase().contains(query) ?? false) ||
            (song.authorName?.toLowerCase().contains(query) ?? false) ||
            song.lyrics.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredSongs = filtered;
    });
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
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          _performVibration();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      widget.categoryName,
                      style: const TextStyle(
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
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _performVibration();
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withAlpha(80),
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
                        onPressed: () {
                          _performVibration();
                          setState(() {
                            if (_fontSize > 12) _fontSize -= 2;
                          });
                        },
                        tooltip: 'Decrease font size',
                      ),
                      Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {
                          _performVibration();
                          setState(() {
                            if (_fontSize < 32) _fontSize += 2;
                          });
                        },
                        tooltip: 'Increase font size',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Language Switcher Chips
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: 12),
                _buildTitleLanguageChip(
                  context: context,
                  label: 'Native',
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

          Expanded(
            child: _filteredSongs.isEmpty
                ? Center(
                    child: Text(
                      'No songs found.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSongs.length,
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return SongCardWidget(
                        song: song,
                        fontSize: _fontSize,
                        showEnglishTitle: _showEnglishTitle,
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
