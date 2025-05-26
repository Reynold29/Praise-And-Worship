import 'package:flutter/material.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';

class SongListScreen extends StatefulWidget {
  final String heroTag;
  final String cardImage;
  const SongListScreen({super.key, required this.heroTag, required this.cardImage});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;
  static const int _pageSize = 20;
  int _currentMax = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        _isLoading = false;
        _currentMax = _pageSize.clamp(0, _songs.length);
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
                    : _songs.isEmpty
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
                              if (index >= _songs.length) return null;
                              final song = _songs[index];
                              return SongCardWidget(song: song);
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 