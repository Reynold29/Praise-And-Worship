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
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _profileImagePath = prefs.getString('profile_image_path');
    });
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

class HomeScreen extends StatelessWidget {
  final String username;
  final String? profileImagePath;
  final VoidCallback onProfileUpdated;
  const HomeScreen({super.key, required this.username, this.profileImagePath, required this.onProfileUpdated});

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
                    // Reload profile image after returning
                    onProfileUpdated();
                  },
                  child: Hero(
                    tag: 'user_profile_avatar',
                    child: profileImagePath != null && profileImagePath!.isNotEmpty
                        ? CircleAvatar(
                            radius: 28.0,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: FileImage(File(profileImagePath!)),
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
                          text: 'Hey, $username  ',
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
                      final bool? hasVibration = await Vibration.hasVibrator();
                      if (hasVibration == true) {
                        Vibration.vibrate(duration: 18, amplitude: 60);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExploreScreen()),
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
                    IconButton.filledTonal(
                      icon: Icon(Icons.search_rounded, color: colorScheme.onPrimaryContainer),
                      onPressed: () async {
                        final bool? hasVibration = await Vibration.hasVibrator();
                        if (hasVibration == true) {
                          Vibration.vibrate(duration: 18, amplitude: 60);
                        }
                        // Handle search icon tap
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton.filledTonal(
                      icon: Icon(Icons.filter_list_rounded, color: colorScheme.onPrimaryContainer),
                      onPressed: () async {
                        final bool? hasVibration = await Vibration.hasVibrator();
                        if (hasVibration == true) {
                          Vibration.vibrate(duration: 18, amplitude: 60);
                        }
                        // Handle filter icon tap
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const SlidingCardsView(),
          ],
        ),
      ),
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
                                    Navigator.of(context).pop();
                                    await _pickImage();
                                  },
                                ),
                                if (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                                  ListTile(
                                    leading: const Icon(Icons.delete_forever_rounded),
                                    title: const Text('Remove Image'),
                                    onTap: () async {
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
                                child: Icon(Icons.account_circle_rounded, color: colorScheme.onPrimaryContainer, size: 80),
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
                    onPressed: _saveProfile,
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
