import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/widgets/sliding_cards.dart';
import 'package:worshipcompanion/screens/explore_Screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/models/song_model.dart';
import 'package:worshipcompanion/widgets/song_card_widget.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/screens/song_detail_screen.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/screens/auth_screen.dart';
import 'package:worshipcompanion/widgets/sync_dialog.dart';
import 'package:worshipcompanion/utils/app_logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = '';
  String? _profileImagePath;
  String? _googleAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _checkForUpdate();
    // Listen for auth state changes so username reloads after Google OAuth
    // redirect comes back (the OAuth callback fires _onAuthStateChange
    // which writes to SharedPreferences before onLoginSuccess pops the sheet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthChanged);
    });
  }

  bool _wasLoggedIn = false;
  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
      _loadUsername();
    } else if (!auth.isLoggedIn && _wasLoggedIn) {
      _wasLoggedIn = false;
      // Immediately clear displayed profile data
      if (mounted) {
        setState(() {
          _username = '';
          _profileImagePath = null;
          _googleAvatarUrl = null;
        });
      }
    }
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final imagePath = prefs.getString('profile_image_path');
    final googleUrl = prefs.getString('google_avatar_url');
    if (mounted) {
      setState(() {
        _username = username;
        _profileImagePath = imagePath;
        _googleAvatarUrl = googleUrl;
      });
    }

    // If logged in but no username set, show mandatory username modal
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && username.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _showUsernameSetupModal();
    }
  }

  void _showUsernameSetupModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UsernameSetupSheet(
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadUsername();
        },
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    // in_app_update is Google Play only — no-op on iOS.
    if (!Platform.isAndroid) return;
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
      AppLogger.d('App', 'Failed to check for update: $e');
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
          googleAvatarUrl: _googleAvatarUrl,
          onProfileUpdated: _loadUsername,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String username;
  final String? profileImagePath;
  final String? googleAvatarUrl;
  final VoidCallback onProfileUpdated;
  const HomeScreen(
      {super.key,
      required this.username,
      this.profileImagePath,
      this.googleAvatarUrl,
      required this.onProfileUpdated});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Shared avatar builder: local file > Google URL > default icon.
/// Adds a coloured ring border and ensures the image is clipped to the circle.
Widget _buildAvatar({
  required String? localPath,
  required String? googleUrl,
  required double radius,
  required double iconSize,
  required ColorScheme colorScheme,
}) {
  Widget avatar;
  if (localPath != null && localPath.isNotEmpty) {
    avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: FileImage(File(localPath)),
    );
  } else if (googleUrl != null && googleUrl.isNotEmpty) {
    avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: NetworkImage(googleUrl),
    );
  } else {
    avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.account_circle_rounded,
        color: colorScheme.onPrimaryContainer,
        size: iconSize * 0.7, // slightly smaller so it doesn't clip
      ),
    );
  }

  // Wrap with a circular border ring
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: colorScheme.primary.withOpacity(0.5),
        width: 2,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: ClipOval(
          child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: avatar,
      )),
    ),
  );
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _favoritesByLang = {};
  bool _loadingFavs = false;
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
    _favoriteProviderInstance =
        Provider.of<FavoriteProvider>(context, listen: false);
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
    setState(() {
      _loadingFavs = true;
    });
    final favKeys = _favoriteProviderInstance.favoriteSongKeys;

    final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
    final allKannada =
        await LocalDatabaseService.instance.fetchAllKannadaSongs();
    final allOther = await LocalDatabaseService.instance.fetchAllOtherSongs();

    Map<String, List<Song>> favs = {
      'English': [],
      'Kannada': [],
      'Other': [],
    };

    for (final key in favKeys) {
      final parts = key.split('|');
      final categoryPart = parts[0].toLowerCase();
      final id = parts[1];

      Song? foundSong;
      String actualDbCategory = '';

      if (categoryPart == 'english' || categoryPart == 'english_data') {
        foundSong = _firstWhereOrNull(allEnglish, (s) => s.id == id);
      } else if (categoryPart == 'kannada' || categoryPart == 'kannada_data') {
        foundSong = _firstWhereOrNull(allKannada, (s) => s.id == id);
      } else {
        foundSong = _firstWhereOrNull(allOther, (s) => s.id == id);
      }

      if (foundSong != null) {
        actualDbCategory = foundSong.category;
        final displayLang = mapCategoryToDisplayLang(actualDbCategory);
        favs[displayLang]!.add(foundSong);
      } else {
        // If not found in local DB, it might be a newly approved song waiting for sync.
        // We log it, but we NO LONGER remove it from FavoriteProvider.
        // This ensures the favorite remains active in the specialized list screens.
        AppLogger.d('HomeScreen', 'Favorite song not in local cache yet: $key');
      }
    }

    AppLogger.d('HomeScreen',
        'Favs loaded — E:${favs['English']!.length} K:${favs['Kannada']!.length} O:${favs['Other']!.length}');
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

  void _performVibration() {
    HapticFeedback.lightImpact();
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
                      snappyPageRoute(page: const UserProfilePage()),
                    );
                    widget.onProfileUpdated();
                  },
                  child: Hero(
                    tag: 'user_profile_avatar',
                    child: _buildAvatar(
                      localPath: widget.profileImagePath,
                      googleUrl: widget.googleAvatarUrl,
                      radius: 28.0,
                      iconSize: 34,
                      colorScheme: colorScheme,
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
                        snappyPageRoute(page: ExploreScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22.0, vertical: 18.0),
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
                      createRectTween: (begin, end) =>
                          MaterialRectArcTween(begin: begin, end: end),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextButton.icon(
                          onPressed: () async {
                            _performVibration();
                            setState(() {
                              _showSearchBar = true;
                            });
                            await Future.delayed(
                                const Duration(milliseconds: 10));
                            await Navigator.of(context).push(HeroDialogRoute(
                              builder: (context) =>
                                  _buildGlobalSearchDialog(context),
                            ));
                            setState(() {
                              _showSearchBar = false;
                              _globalSearchController.clear();
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                          icon: Icon(
                            Icons.search_rounded,
                            size: 24,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Search',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            splashFactory: InkSparkle.splashFactory,
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

  /// Opens the global search dialog as a proper StatefulWidget so songs are
  /// loaded once in initState and filtering is fully in-memory (no per-keystroke
  /// DB calls, no AnimatedSwitcher duplicate-key crashes).
  Widget _buildGlobalSearchDialog(BuildContext context) {
    return _GlobalSearchDialog(
      onSongSelected: (song) {
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
                'lines': SongUtils.parseLyricsToLines(song.lyrics, song.chords),
                'trans_lines':
                    song.transLyrics != null && song.transLyrics!.isNotEmpty
                        ? SongUtils.parseLyricsToLines(
                            song.transLyrics!, song.chords)
                        : null,
              },
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
                  DropdownMenuItem(
                      value: 'Recently Added', child: Text('Recently Added')),
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
  String? _googleAvatarUrl;
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
      _googleAvatarUrl = prefs.getString('google_avatar_url');
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

  void _performVibration() {
    HapticFeedback.lightImpact();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
        final fileName =
            'profile_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newImage =
            await File(croppedFile.path).copy('$path/$fileName');
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
      _username = _usernameController.text.trim();
      _fullname = _fullnameController.text.trim();
    });
    // 1. Persist locally
    await prefs.setString('username', _username);
    await prefs.setString('fullname', _fullname);
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    }

    // 2. Sync to Supabase (if logged in)
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        // Update auth metadata — shows as "Display name" in Supabase Auth dashboard
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': _fullname,
              'username': _username,
            },
          ),
        );
        // Update user_profiles table
        await client.from('user_profiles').upsert({
          'id': userId,
          'username': _username,
          'full_name': _fullname,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      }
    } catch (_) {
      // Offline or not logged in — local save already done, skip silently.
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
                      final hasImage = _profileImagePath != null &&
                          _profileImagePath!.isNotEmpty;
                      await showDialog(
                        context: context,
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          final tt = Theme.of(ctx).textTheme;
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            backgroundColor: cs.surface,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 28, 24, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    'Profile Photo',
                                    style: tt.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Choose an action for your photo',
                                    style: tt.bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 28),
                                  // Pick Image button
                                  FilledButton.icon(
                                    onPressed: () async {
                                      _performVibration();
                                      Navigator.of(ctx).pop();
                                      await _pickImage();
                                    },
                                    icon: const Icon(
                                        Icons.photo_library_rounded,
                                        size: 22),
                                    label: const Text('Pick Image',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Remove Image button
                                  FilledButton.icon(
                                    onPressed: hasImage
                                        ? () async {
                                            _performVibration();
                                            Navigator.of(ctx).pop();
                                            await _removeImage();
                                          }
                                        : null,
                                    icon: const Icon(Icons.delete_rounded,
                                        size: 22),
                                    label: const Text('Remove Image',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      backgroundColor: cs.errorContainer,
                                      foregroundColor: cs.onErrorContainer,
                                      disabledBackgroundColor:
                                          cs.surfaceContainerHighest,
                                      disabledForegroundColor:
                                          cs.onSurfaceVariant.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Cancel
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text('Cancel',
                                        style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildAvatar(
                          localPath: _profileImagePath,
                          googleUrl: _googleAvatarUrl,
                          radius: 54,
                          iconSize: 80,
                          colorScheme: colorScheme,
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
                            child: Icon(Icons.camera_alt_rounded,
                                color: colorScheme.onPrimary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _fullnameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                      textStyle: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      _performVibration();
                      _saveProfile();
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Your profile info and image are stored only on your device, encrypted.',
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),

                // ── Account / Auth section ──────────────────────────────
                const SizedBox(height: 28),
                _AccountSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mandatory Username Setup Sheet ───────────────────────────────────────────
// Shown after first login when username is empty. Cannot be dismissed.

class _UsernameSetupSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _UsernameSetupSheet({required this.onSaved});

  @override
  State<_UsernameSetupSheet> createState() => _UsernameSetupSheetState();
}

class _UsernameSetupSheetState extends State<_UsernameSetupSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFromPrefs();
  }

  Future<void> _prefillFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('username') ?? '';
    if (stored.isNotEmpty && mounted) {
      setState(() => _ctrl.text = stored);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _ctrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter a username to continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);

      // Sync to Supabase
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'username': username}),
        );
        await client.from('user_profiles').upsert(
          {
            'id': uid,
            'username': username,
            'updated_at': DateTime.now().toIso8601String()
          },
          onConflict: 'id',
        );
      }
    } catch (_) {
      // Local save succeeded — Supabase sync will retry next profile save
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false, // truly non-dismissible
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.person_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              'Choose a username',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'This is how others will see you.\nYou can always change it later in your profile.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. John',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: _error,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Continue',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Account Section ──────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'ACCOUNT',
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),

        if (!auth.isLoggedIn)
          // Only show the sign-in card when social login is enabled
          if (context.watch<AppConfigProvider>().socialLoginEnabled)
            _SignInCard(context, auth, cs, tt)
          else
            const SizedBox.shrink()
        else
          _SignedInCard(context, auth, cs, tt),
      ],
    );
  }

  Widget _SignInCard(
      BuildContext context, AuthProvider auth, ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withOpacity(0.5),
            cs.secondaryContainer.withOpacity(0.3)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final favProv =
                Provider.of<FavoriteProvider>(context, listen: false);
            final localKeys =
                favProv.favoriteSongKeys.where((k) => k.isNotEmpty).toList();
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AuthScreen(
                  onSuccess: () {},
                ),
              ),
            );
            // After successful login, show sync dialog if there were local favourites
            if ((result == true) && context.mounted) {
              final updatedAuth =
                  Provider.of<AuthProvider>(context, listen: false);
              if (updatedAuth.isLoggedIn && localKeys.isNotEmpty) {
                await showSyncDialog(context);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.cloud_outlined, color: cs.onPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign in to sync favourites',
                          style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const SizedBox(height: 2),
                      Text('Access your songs on any device',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _SignedInCard(
      BuildContext context, AuthProvider auth, ColorScheme cs, TextTheme tt) {
    final initial = (auth.displayName?.isNotEmpty == true)
        ? auth.displayName![0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(initial,
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(
              auth.displayName ?? 'User',
              style: tt.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            subtitle: Text(
              auth.email ?? '',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Synced',
                  style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Manual sync button
          ListTile(
            leading: Icon(Icons.cloud_sync_rounded, color: cs.secondary),
            title: Text('Sync Favourites',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
            subtitle: Text('Merge local & cloud favourites',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            onTap: () => showSyncDialog(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Sign out
          ListTile(
            leading: Icon(Icons.logout_rounded, color: cs.error),
            title: Text('Sign Out',
                style: tt.bodyMedium?.copyWith(color: cs.error)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                      'Your favourites will still be available locally.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await auth.signOut();
              }
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Delete account
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: cs.error),
            title: Text('Delete Account',
                style: tt.bodyMedium
                    ?.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
            subtitle: Text('Permanently removes your account and all data',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            onTap: () async {
              // First confirm
              final step1 = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  icon: Icon(Icons.warning_amber_rounded,
                      color: cs.error, size: 36),
                  title: const Text('Delete your account?'),
                  content: const Text(
                      'This will permanently delete your account, all your synced favourites, and any songs you submitted for review. This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              );
              if (step1 != true || !context.mounted) return;

              // Second confirm
              final step2 = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Are you absolutely sure?'),
                  content: const Text(
                      'Your account will be permanently deleted. This action is irreversible.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Yes, Delete Everything'),
                    ),
                  ],
                ),
              );
              if (step2 != true || !context.mounted) return;

              await auth.deleteAccount();
              if (!context.mounted) return;

              // Clear local profile data
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('username');
              await prefs.remove('fullname');
              await prefs.remove('profile_image_path');

              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Your account has been deleted.'),
                      duration: Duration(seconds: 4)),
                );
              }
            },
          ),
        ],
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

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FavoriteProvider _favoriteProviderInstance;
  bool _loadingFavs = true;
  List<Song> _englishFavs = [];
  List<Song> _kannadaFavs = [];
  List<Song> _otherFavs = [];
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChangedWithVibration);
    _tabController.animation?.addStatusListener(_onTabAnimationStatus);
    _favoriteProviderInstance =
        Provider.of<FavoriteProvider>(context, listen: false);
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
      _performVibration();
      _lastTabIndex = _tabController.index;
    }
  }

  void _onTabAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_tabController.index != _lastTabIndex) {
        _performVibration();
        _lastTabIndex = _tabController.index;
      }
    }
  }

  void _onFavoritesChanged() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loadingFavs = true;
    });
    final favKeys = _favoriteProviderInstance.favoriteSongKeys;
    // English
    final allEnglish = await LocalDatabaseService.instance.fetchAllSongs();
    final englishFavIds = favKeys
        .where((k) => k.startsWith('english_data|') || k.startsWith('english|'))
        .map((k) => k.split('|')[1])
        .toSet();
    final englishFavs =
        allEnglish.where((s) => englishFavIds.contains(s.id)).toList();
    // Kannada
    final allKannada =
        await LocalDatabaseService.instance.fetchAllKannadaSongs();
    final kannadaFavIds = favKeys
        .where((k) => k.startsWith('kannada_data|') || k.startsWith('kannada|'))
        .map((k) => k.split('|')[1])
        .toSet();
    final kannadaFavs =
        allKannada.where((s) => kannadaFavIds.contains(s.id)).toList();
    // Other
    final allOther = await LocalDatabaseService.instance.fetchAllOtherSongs();
    final otherFavIds = favKeys
        .where((k) => k.startsWith('other_data|') || k.startsWith('other|'))
        .map((k) => k.split('|')[1])
        .toSet();
    final otherFavs =
        allOther.where((s) => otherFavIds.contains(s.id)).toList();
    setState(() {
      _englishFavs = englishFavs;
      _kannadaFavs = kannadaFavs;
      _otherFavs = otherFavs;
      _loadingFavs = false;
    });
  }

  void _performVibration() {
    HapticFeedback.lightImpact();
  }

  Future<void> _removeFromFavorites(Song song, String category) async {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
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
              labelStyle:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.titleMedium,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 18.0),
                  child: _buildTabWithBadge(
                      'English', _englishFavs.length, colorScheme),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 18.0),
                  child: _buildTabWithBadge(
                      'Kannada', _kannadaFavs.length, colorScheme),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 18.0),
                  child: _buildTabWithBadge(
                      'Other', _otherFavs.length, colorScheme),
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
                _buildFavSection('Other', _otherFavs, 'other_data'),
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
    final isKannada = currentTab == 1;
    final lang = isEnglish ? 'English' : (isKannada ? 'Kannada' : 'Other');
    final favs =
        isEnglish ? _englishFavs : (isKannada ? _kannadaFavs : _otherFavs);
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
        content: Text(
            'Are you sure you want to remove all $lang favorites? This cannot be undone.'),
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
      final favoriteProvider =
          Provider.of<FavoriteProvider>(context, listen: false);
      final categoryKey = isEnglish
          ? 'english_data'
          : (isKannada ? 'kannada_data' : 'other_data');
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Search $lang favorites...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withAlpha(80),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                  child: Text('No $lang favorites yet.',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ),
              )
            else ...[
              Padding(
                padding:
                    const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$lang Favorites',
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
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
                            icon: Icon(Icons.heart_broken_rounded,
                                color: colorScheme.error, size: 22),
                            tooltip: 'Remove from Favorites',
                            onPressed: () {
                              _performVibration();
                              _removeFromFavorites(song, song.category);
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
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return snappyTransition(context, animation, secondaryAnimation, child);
  }

  @override
  bool get maintainState => true;
}

// ─── Global Search Dialog ─────────────────────────────────────────────────────
// A self-contained StatefulWidget so we can:
//  • Fetch all songs ONCE in initState (no per-keystroke DB hit)
//  • Filter completely in-memory (synchronous, instant)
//  • Debounce filtering with a Timer so rapid typing doesn't spam rebuilds
//  • Use plain if/else instead of AnimatedSwitcher to avoid duplicate-key crash

class _GlobalSearchDialog extends StatefulWidget {
  final void Function(Song song) onSongSelected;
  const _GlobalSearchDialog({required this.onSongSelected});

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;

  List<Song> _allSongs = [];
  List<Song> _results = [];
  String _query = '';
  String _filterLang = 'All';
  String _sortOrder = 'A-Z';
  bool _loading = true; // true only while initial load is happening

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final english = await LocalDatabaseService.instance.fetchAllSongs();
    final kannada = await LocalDatabaseService.instance.fetchAllKannadaSongs();
    final other = await LocalDatabaseService.instance.fetchAllOtherSongs();
    if (!mounted) return;
    setState(() {
      _allSongs = [...english, ...kannada, ...other];
      _loading = false;
    });
    // Show all songs immediately on open
    _applyFilter();
  }

  // Fully in-memory — no async, no DB, never races.
  void _applyFilter() {
    final q = _query.trim().toLowerCase();

    // Known scraper artifacts — exclude regardless of DB cleanup state
    const _badTitles = {
      'search christian lyrics',
      'search christian',
      'christian lyrics',
    };

    List<Song> filtered = _allSongs.where((s) {
      // Strip scraper artifacts
      if (_badTitles.any((bad) => s.title.trim().toLowerCase().contains(bad)))
        return false;

      if (_filterLang == 'English') {
        final cat = s.category.trim().toLowerCase();
        if (cat != 'english_data' && cat != 'english') return false;
      }
      if (_filterLang == 'Kannada') {
        final cat = s.category.trim().toLowerCase();
        if (cat != 'kannada_data' && cat != 'kannada') return false;
      }
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          (s.englishTitle?.toLowerCase().contains(q) ?? false) ||
          (s.authorName?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (_sortOrder == 'A-Z') {
      filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortOrder == 'Z-A') {
      filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (_sortOrder == 'Recently Added') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (mounted) setState(() => _results = filtered);
  }

  void _onQueryChanged(String val) {
    // Update the query immediately so the clear button shows/hides right away
    if (mounted) setState(() => _query = val);
    // Debounce the actual filter by 150ms so mid-word typing isn't sluggish
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _applyFilter);
  }

  void _onFilterChanged(String? lang, String? sort) {
    if (lang != null && mounted) setState(() => _filterLang = lang);
    if (sort != null && mounted) setState(() => _sortOrder = sort);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final langLabels = {
      'All': 'All',
      'English': '🇬🇧 English',
      'Kannada': 'ಕ Kannada'
    };
    final sortLabels = {
      'A-Z': 'A → Z',
      'Z-A': 'Z → A',
      'Recently Added': '🕐 Recent'
    };

    return Center(
      child: Hero(
        tag: 'global_search_hero',
        createRectTween: (begin, end) =>
            MaterialRectArcTween(begin: begin, end: end),
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          elevation: 12,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search bar ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search all songs…',
                          hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.45)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: colorScheme.primary),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded,
                                      color: colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _ctrl.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Filter chips ─────────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in langLabels.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(entry.value,
                                style: textTheme.labelMedium?.copyWith(
                                    color: _filterLang == entry.key
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant)),
                            selected: _filterLang == entry.key,
                            onSelected: (_) =>
                                _onFilterChanged(entry.key, null),
                            selectedColor: colorScheme.primary,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                          width: 1,
                          height: 22,
                          color: colorScheme.outline.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      for (final entry in sortLabels.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(entry.value,
                                style: textTheme.labelMedium?.copyWith(
                                    color: _sortOrder == entry.key
                                        ? colorScheme.onSecondary
                                        : colorScheme.onSurfaceVariant)),
                            selected: _sortOrder == entry.key,
                            onSelected: (_) =>
                                _onFilterChanged(null, entry.key),
                            selectedColor: colorScheme.secondary,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Fixed-height result pane — no AnimatedSwitcher ───────────
                SizedBox(
                  height: 340,
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: colorScheme.primary, strokeWidth: 2.5),
                              const SizedBox(height: 12),
                              Text('Loading songs…',
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : _results.isEmpty && _query.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 48,
                                      color:
                                          colorScheme.error.withOpacity(0.45)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No songs match "$_query"',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.55)),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_query.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 6),
                                    child: Text(
                                      '${_results.length} song${_results.length == 1 ? '' : 's'} found',
                                      style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5)),
                                    ),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _results.length,
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (context, idx) {
                                      final song = _results[idx];
                                      final isKannada = song.category
                                          .toLowerCase()
                                          .contains('kannada');
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () =>
                                              widget.onSongSelected(song),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: isKannada
                                                        ? colorScheme
                                                            .tertiaryContainer
                                                        : colorScheme
                                                            .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    song.title.isNotEmpty
                                                        ? song.title[0]
                                                            .toUpperCase()
                                                        : '♪',
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isKannada
                                                          ? colorScheme
                                                              .onTertiaryContainer
                                                          : colorScheme
                                                              .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        song.title,
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onSurface,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if ((song.authorName ??
                                                              '')
                                                          .isNotEmpty)
                                                        Text(
                                                          song.authorName!,
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: colorScheme
                                                                      .onSurfaceVariant),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    size: 14,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.3)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
