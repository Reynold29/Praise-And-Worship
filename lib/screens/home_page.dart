import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/widgets/sliding_cards.dart';
import 'package:worshipcompanion/screens/explore_Screen.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = '';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _checkForUpdate();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      print('Failed to check for update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: HomeScreen(
          username: _username,
          profileImagePath: _profileImagePath,
          onProfileUpdated: _loadUsername,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String username;
  final String? profileImagePath;
  final VoidCallback onProfileUpdated;
  const HomeScreen({super.key, required this.username, this.profileImagePath, required this.onProfileUpdated});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _favoritesByLang = {};
  bool _loadingFavs = true;
  late FavoriteProvider _favoriteProviderInstance;
  bool _showSearchBar = false;
  final TextEditingController _globalSearchController = TextEditingController();
  String _searchQuery = '';
  String _filterLang = 'All';
  String _sortOrder = 'A-Z';
  List<Song> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _favoriteProviderInstance = Provider.of<FavoriteProvider>(context, listen: false);
    _favoriteProviderInstance.addListener(_onFavoritesChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoriteProviderInstance.removeListener(_onFavoritesChanged);
    _globalSearchController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() { _loadingFavs = true; });
    final favKeys = _favoriteProviderInstance.favoriteSongKeys;
    print('[_loadFavorites HomeScreen] Fetched favKeys from provider: $favKeys');

    final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
    final allKannada = await LocalDatabaseService.instance.fetchAllKannadaSongs();
    print('[_loadFavorites HomeScreen] Fetched English songs: ${allEnglish.length}, Kannada songs: ${allKannada.length}');

    Map<String, List<Song>> favs = {
      'English': [],
      'Kannada': [],
      'Other': [],
    };

    for (final key in favKeys) {
      final parts = key.split('|');
      if (parts.length != 2) {
        print('[_loadFavorites HomeScreen] Skipping invalid key: $key');
        continue;
      }
      final id = parts[1];
      print('[_loadFavorites HomeScreen] Processing key: $key, id: $id');

      Song? foundSong;
      String actualDbCategory = '';

      foundSong = _firstWhereOrNull(allEnglish, (s) => s.id == id);
      if (foundSong != null) {
        actualDbCategory = foundSong.category;
        print('[_loadFavorites HomeScreen] Found English song: ${foundSong.title}, actualDbCategory: ${foundSong.category}');
      } else {
        foundSong = _firstWhereOrNull(allKannada, (s) => s.id == id);
        if (foundSong != null) {
          actualDbCategory = foundSong.category;
          print('[_loadFavorites HomeScreen] Found Kannada song: ${foundSong.title}, actualDbCategory: ${foundSong.category}');
        }
      }

      if (foundSong != null) {
        String displayLang;
        // Use normalization function for mapping
        displayLang = mapCategoryToDisplayLang(actualDbCategory);
        favs[displayLang]!.add(foundSong);
        print('[_loadFavorites HomeScreen] Added song to category: ' + displayLang + ', title: ' + foundSong.title);
      } else {
        print('[_loadFavorites HomeScreen] Song not found for ID: $id in either English or Kannada databases. Removing from favorites.');
        _favoriteProviderInstance.toggleFavorite('', id);
      }
    }
    print('[_loadFavorites HomeScreen] Final favs map: $favs');
    setState(() {
      _favoritesByLang = favs;
      _loadingFavs = false;
    });
  }

  T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  void _performVibration({int duration = 18}) async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: duration, amplitude: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    _performVibration();
                    await Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const UserProfilePage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                        reverseTransitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    widget.onProfileUpdated();
                  },
                  child: Hero(
                    tag: 'user_profile_avatar',
                    child: widget.profileImagePath != null && widget.profileImagePath!.isNotEmpty
                        ? CircleAvatar(
                            radius: 28.0,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: FileImage(File(widget.profileImagePath!)),
                          )
                        : CircleAvatar(
                            radius: 28.0,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.account_circle_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 34,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 18.0),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hey, ${widget.username}  ',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        WidgetSpan(
                          child: Icon(
                            Icons.waving_hand_rounded,
                            size: textTheme.headlineSmall?.fontSize ?? 26,
                            color: Colors.amber.shade700,
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: colorScheme.surfaceVariant.withOpacity(0.85),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      _performVibration();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => ExploreScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                          reverseTransitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Your Personal',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              Text(
                                'Worship Companion',
                                style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 22,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discover Melodies',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Hero(
                      tag: 'global_search_hero',
                      createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                      child: Material(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          splashColor: colorScheme.onPrimary.withOpacity(0.18),
                          highlightColor: colorScheme.onPrimary.withOpacity(0.08),
                          onTap: () async {
                            _performVibration();
                            setState(() {
                              _showSearchBar = true;
                            });
                            await Future.delayed(const Duration(milliseconds: 10));
                            await Navigator.of(context).push(HeroDialogRoute(
                              builder: (context) => _buildGlobalSearchDialog(context),
                            ));
                            setState(() {
                              _showSearchBar = false;
                              _globalSearchController.clear();
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.search_rounded,
                              size: 28,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            SlidingCardsView(onFavoriteToggled: _loadFavorites),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSearchDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: Hero(
            tag: 'global_search_hero',
            createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
            child: Material(
              color: Colors.black,
              elevation: 8,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _globalSearchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search all songs...',
                              prefixIcon: Icon(Icons.search, color: Colors.white),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.grey[900],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) async {
                              setState(() {
                                _searchQuery = val;
                                _searching = true;
                              });
                              final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
                              final allKannada = await LocalDatabaseService.instance.fetchAllKannadaSongs();
                              final query = val.toLowerCase();
                              List<Song> results = [
                                ...allEnglish,
                                ...allKannada,
                              ].where((s) {
                                if (_filterLang == 'English' && (s.category.trim().toLowerCase() != 'english_data' && s.category.trim().toLowerCase() != 'english')) return false;
                                if (_filterLang == 'Kannada' && (s.category.trim().toLowerCase() != 'kannada_data' && s.category.trim().toLowerCase() != 'kannada')) return false;
                                return query.isEmpty ||
                                  s.title.toLowerCase().contains(query) ||
                                  (s.authorName?.toLowerCase().contains(query) ?? false);
                              }).toList();
                              // Sort
                              if (_sortOrder == 'A-Z') {
                                results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                              } else if (_sortOrder == 'Z-A') {
                                results.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
                              } else if (_sortOrder == 'Recently Added') {
                                results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                              }
                              setState(() {
                                _searchResults = results;
                                _searching = false;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _filterLang,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'Kannada', child: Text('Kannada')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterLang = val!;
                            });
                            _globalSearchController.text = _globalSearchController.text; // trigger search
                          },
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _sortOrder,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                            DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
                            DropdownMenuItem(value: 'Recently Added', child: Text('Recently Added')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _sortOrder = val!;
                            });
                            _globalSearchController.text = _globalSearchController.text; // trigger search
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No results found.', style: TextStyle(color: colorScheme.onPrimary, fontSize: 16)),
                      )
                    else if (_searchResults.isNotEmpty)
                      SizedBox(
                        height: 350,
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, idx) {
                            final song = _searchResults[idx];
                            return ListTile(
                              title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Text(song.authorName ?? '', style: const TextStyle(color: Colors.white70)),
                              onTap: () {
                                Navigator.of(context).pop();
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _filterLang,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Kannada', child: Text('Kannada')),
                ],
                onChanged: (val) {
                  setState(() {
                    _filterLang = val!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _sortOrder,
                items: const [
                  DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                  DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
                  DropdownMenuItem(value: 'Recently Added', child: Text('Recently Added')),
                ],
                onChanged: (val) {
                  setState(() {
                    _sortOrder = val!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _username = '';
  String _fullname = '';
  String? _profileImagePath;
  final _usernameController = TextEditingController();
  final _fullnameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _fullname = prefs.getString('fullname') ?? '';
      _profileImagePath = prefs.getString('profile_image_path');
      _usernameController.text = _username;
      _fullnameController.text = _fullname;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullnameController.dispose();
    super.dispose();
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newImage = await File(croppedFile.path).copy('$path/$fileName');
        setState(() {
          _profileImagePath = newImage.path;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', newImage.path);
      }
    }
  }

  Future<void> _removeImage() async {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      final file = File(_profileImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _profileImagePath = null;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');
    }
  }

  void _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = _usernameController.text;
      _fullname = _fullnameController.text;
    });
    await prefs.setString('username', _username);
    await prefs.setString('fullname', _fullname);
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: colorScheme.surface,
        elevation: 1,
      ),
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'user_profile_avatar',
                  child: GestureDetector(
                    onTap: () async {
                      _performVibration();
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library_rounded),
                                  title: const Text('Pick Image'),
                                  onTap: () async {
                                    _performVibration();
                                    Navigator.of(context).pop();
                                    await _pickImage();
                                  },
                                ),
                                if (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                                  ListTile(
                                    leading: const Icon(Icons.delete_forever_rounded),
                                    title: const Text('Remove Image'),
                                    onTap: () async {
                                      _performVibration();
                                      Navigator.of(context).pop();
                                      await _removeImage();
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _profileImagePath != null && _profileImagePath!.isNotEmpty
                            ? CircleAvatar(
                                radius: 54,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: FileImage(File(_profileImagePath!)),
                              )
                            : CircleAvatar(
                                radius: 54,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.account_circle_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 80,
                                ),
                              ),
                        Positioned(
                          bottom: 6,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Icon(Icons.camera_alt_rounded, color: colorScheme.onPrimary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _fullnameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      _performVibration();
                      _saveProfile();
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Your profile info and image are stored only on your device, encrypted. Nothing is uploaded to any server.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- FAVORITES SCREEN ---
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FavoriteProvider _favoriteProviderInstance;
  bool _loadingFavs = true;
  List<Song> _englishFavs = [];
  List<Song> _kannadaFavs = [];
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChangedWithVibration);
    _tabController.animation?.addStatusListener(_onTabAnimationStatus);
    _favoriteProviderInstance = Provider.of<FavoriteProvider>(context, listen: false);
    _favoriteProviderInstance.addListener(_onFavoritesChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoriteProviderInstance.removeListener(_onFavoritesChanged);
    _tabController.removeListener(_onTabChangedWithVibration);
    _tabController.animation?.removeStatusListener(_onTabAnimationStatus);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChangedWithVibration() {
    if (_tabController.index != _lastTabIndex) {
      _performVibration(duration: 8);
      _lastTabIndex = _tabController.index;
    }
  }

  void _onTabAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_tabController.index != _lastTabIndex) {
        _performVibration(duration: 8);
        _lastTabIndex = _tabController.index;
      }
    }
  }

  void _onFavoritesChanged() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() { _loadingFavs = true; });
    final favKeys = _favoriteProviderInstance.favoriteSongKeys;
    // English
    final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
    final englishFavIds = favKeys
      .where((k) => k.startsWith('english_data|'))
      .map((k) => k.split('|')[1])
      .toSet();
    final englishFavs = allEnglish.where((s) => englishFavIds.contains(s.id)).toList();
    // Kannada
    final allKannada = await LocalDatabaseService.instance.fetchAllKannadaSongs();
    final kannadaFavIds = favKeys
      .where((k) => k.startsWith('kannada_data|'))
      .map((k) => k.split('|')[1])
      .toSet();
    final kannadaFavs = allKannada.where((s) => kannadaFavIds.contains(s.id)).toList();
    setState(() {
      _englishFavs = englishFavs;
      _kannadaFavs = kannadaFavs;
      _loadingFavs = false;
    });
  }

  void _performVibration({int duration = 18}) async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: duration, amplitude: 60);
    }
  }

  Future<void> _removeFromFavorites(Song song, String category) async {
    final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
    _performVibration();
    favoriteProvider.toggleFavorite(category, song.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed from favorites'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => favoriteProvider.toggleFavorite(category, song.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(0),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.titleMedium,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                  child: _buildTabWithBadge('English', _englishFavs.length, colorScheme),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                  child: _buildTabWithBadge('Kannada', _kannadaFavs.length, colorScheme),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear All Favorites in Tab',
            onPressed: _loadingFavs ? null : () => _showClearFavoritesDialog(),
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: _loadingFavs
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFavSection('English', _englishFavs, 'english_data'),
                _buildFavSection('Kannada', _kannadaFavs, 'kannada_data'),
              ],
            ),
    );
  }

  Widget _buildTabWithBadge(String label, int count, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: 6),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  void _showClearFavoritesDialog() async {
    final currentTab = _tabController.index;
    final isEnglish = currentTab == 0;
    final lang = isEnglish ? 'English' : 'Kannada';
    final favs = isEnglish ? _englishFavs : _kannadaFavs;
    if (favs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $lang favorites to clear.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $lang Favorites?'),
        content: Text('Are you sure you want to remove all $lang favorites? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      final categoryKey = isEnglish ? 'english_data' : 'kannada_data';
      for (final song in favs) {
        await favoriteProvider.toggleFavorite(categoryKey, song.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All $lang favorites cleared.')),
      );
    }
  }

  Widget _buildFavSection(String lang, List<Song> songs, String categoryKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final searchController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setState) {
        // Compute filtered songs once per build
        final query = searchController.text.toLowerCase();
        final filteredSongs = songs.where((s) {
          return query.isEmpty ||
            s.title.toLowerCase().contains(query) ||
            (s.authorName?.toLowerCase().contains(query) ?? false);
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search $lang favorites...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withAlpha(80),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: colorScheme.primary),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),
            if (songs.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No $lang favorites yet.', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$lang Favorites', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, idx) {
                    final song = filteredSongs[idx];
                    return Stack(
                      children: [
                        SongCardWidget(
                          song: song,
                          fontSize: 16,
                          hideFavoriteButton: true,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            icon: Icon(Icons.heart_broken_rounded, color: colorScheme.error, size: 22),
                            tooltip: 'Remove from Favorites',
                            onPressed: () {
                              _performVibration();
                              _removeFromFavorites(song, categoryKey);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Helper to normalize category to display language
String mapCategoryToDisplayLang(String category) {
  final normalized = category.trim().toLowerCase();
  if (normalized == 'english_data' || normalized == 'english') {
    return 'English';
  } else if (normalized == 'kannada_data' || normalized == 'kannada') {
    return 'Kannada';
  } else {
    return 'Other';
  }
}

// Custom route for hero morphing dialog
class HeroDialogRoute<T> extends PageRoute<T> {
  HeroDialogRoute({
    required this.builder,
    RouteSettings? settings,
    this.barrierLabel,
  }) : super(settings: settings);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => true;
  @override
  String? barrierLabel;
  @override
  Color get barrierColor => Colors.black54;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
      child: child,
    );
  }

  @override
  bool get maintainState => true;
}
