import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'add_manual_song_screen.dart';
import '../services/vision_service.dart';
import '../services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:worshipcompanion/screens/home_page.dart';
import 'package:worshipcompanion/screens/add_song_options_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ScanSongScreen extends StatefulWidget {
  const ScanSongScreen({Key? key}) : super(key: key);

  @override
  State<ScanSongScreen> createState() => _ScanSongScreenState();
}

class _ScanSongScreenState extends State<ScanSongScreen> {
  bool _isLoading = false;

  Future<void> _handleImage({required bool fromCamera}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final status = fromCamera
          ? await Permission.camera.request()
          : await Permission.photos.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied.')),
        );
        return;
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      final visionApiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (visionApiKey.isEmpty || geminiApiKey.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('API keys not set. Please check your .env file.')),
        );
        return;
      }
      String extractedText = '';
      Map<String, String> parsed = {};
      try {
        extractedText = await VisionService.extractTextFromImage(
            File(picked.path), visionApiKey);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vision API error: $e')),
        );
        return;
      }
      try {
        parsed = await GeminiService.parseSongText(extractedText, geminiApiKey,
            addChords: false);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gemini API error: $e')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddManualSongScreen(
            initialTitle: parsed['title'] ?? '',
            initialLyrics: parsed['lyrics'] ?? '',
            initialAuthor: parsed['author'] ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _checkAndHandleImage({required bool fromCamera}) async {
    AppLogger.d('DEBUG', 'Checking requirements for scan, fromCamera: $fromCamera');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Checking Requirements',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(strokeWidth: 4),
            const SizedBox(height: 22),
            const Text(
              'Making sure your phone is connected to the internet...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    final connectivityFuture = Connectivity().checkConnectivity();
    await Future.delayed(const Duration(milliseconds: 500));
    final connectivityResult = await connectivityFuture;
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss dialog
    }
    AppLogger.d('DEBUG', 'Connectivity result: $connectivityResult');
    bool noInternet = false;
    if (connectivityResult is List) {
      // Newer versions may return a list
      noInternet = connectivityResult.length == 1 &&
          connectivityResult.first == ConnectivityResult.none;
      AppLogger.d('DEBUG', 'List connectivityResult, noInternet: $noInternet');
    } else {
      // Older versions return a single value
      noInternet = connectivityResult == ConnectivityResult.none;
      AppLogger.d('DEBUG', 'Single connectivityResult, noInternet: $noInternet');
    }
    if (noInternet) {
      if (!mounted) return;
      AppLogger.d('DEBUG', 'No internet, showing snackbar and aborting.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No internet connection. Please connect to the internet to use this feature.')),
      );
      return; // Do NOT call _handleImage if offline
    }
    AppLogger.d('DEBUG', 'Internet available, proceeding to handle image.');
    await _handleImage(fromCamera: fromCamera);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Updated text style for loading messages
    final loadingTextStyle = TextStyle(
      fontSize: 21.0, // Increased font size
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0, // Slightly adjusted letter spacing
      color: colorScheme.onSurfaceVariant,
    );
    const typewriterSpeed = Duration(milliseconds: 70);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Song from Image'),
      ),
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          // Added for small screen heights
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 8.0, left: 20, right: 20),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'AI-Powered Song Scanner',
                      // Using headlineSmall for more prominence
                      textStyle: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: colorScheme.onBackground,
                      ),
                      speed: const Duration(milliseconds: 60),
                      cursor: '|',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  isRepeatingAnimation: false,
                  repeatForever: false,
                  displayFullTextOnTap: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  _isLoading
                      ? 'Processing your song, please wait...'
                      : 'Choose an image of a song to get started',
                  style: textTheme.titleMedium?.copyWith(
                    letterSpacing: 1.0,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24), // Increased space before card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Card(
                  elevation: 4, // Slightly increased elevation
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(24)), // Softer corners
                  color: colorScheme.surface
                      .withOpacity(0.95), // Using surface color for card
                  clipBehavior: Clip
                      .antiAlias, // Ensures content respects rounded corners
                  child: Padding(
                    padding: const EdgeInsets.all(
                        20.0), // Uniform padding, slightly reduced
                    child: _isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize:
                                MainAxisSize.min, // Helps card fit content
                            children: [
                              Builder(
                                builder: (context) {
                                  try {
                                    return Lottie.asset(
                                      'assets/animations/ai_animation.json',
                                      width:
                                          110, // Slightly reduced Lottie size
                                      height: 110,
                                      repeat: true,
                                      fit: BoxFit.contain,
                                    );
                                  } catch (e) {
                                    AppLogger.d('App', 'Error loading Lottie animation: $e');
                                    return Icon(Icons.error_outline,
                                        color: Colors.red, size: 60);
                                  }
                                },
                              ),
                              const SizedBox(
                                  height: 20), // Space between Lottie and text
                              Container(
                                constraints: const BoxConstraints(
                                    minHeight: 55), // Stable height for text
                                alignment: Alignment.center,
                                child: AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                        'Velocity AI is Scanning...',
                                        textStyle: loadingTextStyle,
                                        speed: typewriterSpeed,
                                        cursor: '|',
                                        textAlign: TextAlign.center),
                                    TypewriterAnimatedText(
                                        'Extracting text from image...',
                                        textStyle: loadingTextStyle,
                                        speed: typewriterSpeed,
                                        cursor: '|',
                                        textAlign: TextAlign.center),
                                    TypewriterAnimatedText(
                                        'Processing song structure...',
                                        textStyle: loadingTextStyle,
                                        speed: typewriterSpeed,
                                        cursor: '|',
                                        textAlign: TextAlign.center),
                                    TypewriterAnimatedText(
                                        'AI is working hard, please wait...',
                                        textStyle: loadingTextStyle,
                                        speed: typewriterSpeed,
                                        cursor: '|',
                                        textAlign: TextAlign.center),
                                  ],
                                  isRepeatingAnimation: true,
                                  repeatForever: true,
                                  pause: const Duration(
                                      milliseconds: 1200), // Adjusted pause
                                  displayFullTextOnTap: true,
                                ),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            // Button layout remains the same
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >
                                  400; // This is unlikely given parent constraint
                              return isWide
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildScanButton(
                                            icon: Icons.camera_alt_rounded,
                                            label: 'Scan with Camera',
                                            onTap: () => _checkAndHandleImage(
                                                fromCamera: true)),
                                        _buildScanButton(
                                            icon: Icons.photo_library_rounded,
                                            label: 'Pick from Gallery',
                                            onTap: () => _checkAndHandleImage(
                                                fromCamera: false)),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildScanButton(
                                            icon: Icons.camera_alt_rounded,
                                            label: 'Scan with Camera',
                                            onTap: () => _checkAndHandleImage(
                                                fromCamera: true)),
                                        const SizedBox(
                                            height:
                                                16), // Slightly reduced space
                                        _buildScanButton(
                                            icon: Icons.photo_library_rounded,
                                            label: 'Pick from Gallery',
                                            onTap: () => _checkAndHandleImage(
                                                fromCamera: false)),
                                      ],
                                    );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      icon: Icon(icon,
          size: 26, color: colorScheme.onPrimary), // Slightly smaller icon
      label: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12.0, horizontal: 4.0), // Adjusted padding
        child: Text(
          label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
              letterSpacing: 0.5), // Adjusted style
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(180, 56), // Slightly adjusted size
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // Softer radius
        elevation: 3,
        shadowColor: colorScheme.primary.withOpacity(0.2),
      ),
      onPressed: onTap,
    );
  }
}
