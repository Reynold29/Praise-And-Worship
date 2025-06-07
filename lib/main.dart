import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/screens/home_page.dart';
import 'package:worshipcompanion/screens/onboarding_screen.dart';
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/local_database_service.dart';
import 'services/realtime_sync_service.dart';
import 'package:inditrans/inditrans.dart' as inditrans;
import 'package:worshipcompanion/widgets/favorite_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize inditrans for transliteration support
  await inditrans.init();

  // By default, dotenv.load() looks for ".env" in the project root.
  // Ensure your .env file is in the project root, not in lib/
  await dotenv.load(fileName: ".env");

  // Defensive: Track if Supabase is initialized
  bool supabaseInitialized = false;
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!, // Uses the URL from .env
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Uses the "anon" key from .env
    );
    supabaseInitialized = true;
  } catch (e) {
    print('Supabase initialization failed: '
        '[31m$e[0m');
    // Proceed without Supabase; local DB will be used
  }

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? false;

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize FavoriteProvider and load favorites
  final favoriteProvider = FavoriteProvider();
  // No need to await favoriteProvider._loadFavorites() as it's called in its constructor

  // --- Sync local DB from Supabase if online and Supabase is initialized ---
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult != ConnectivityResult.none && supabaseInitialized) {
    await LocalDatabaseService.instance.syncFromSupabase();
  }
  // Start real-time listener only if Supabase is initialized
  if (supabaseInitialized) {
    RealtimeSyncService.instance.startListening();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: favoriteProvider),
      ],
      child: MyApp(showOnboarding: showOnboarding, supabaseInitialized: supabaseInitialized),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  final bool supabaseInitialized;

  const MyApp({super.key, required this.showOnboarding, this.supabaseInitialized = true});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) async {
      if (result != ConnectivityResult.none && widget.supabaseInitialized) {
        await LocalDatabaseService.instance.syncFromSupabase();
        // Also refresh favorites in case they were updated by sync
        if (mounted) {
          Provider.of<FavoriteProvider>(context, listen: false).refreshFavorites();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const String appFontFamily = 'ProductSans'; // Define the font family name

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamicFromBuilder, ColorScheme? darkDynamicFromBuilder) {
        ColorScheme lightSchemeToUse;
        ColorScheme darkSchemeToUse;

        if (lightDynamicFromBuilder != null && darkDynamicFromBuilder != null) {
          // Dynamic colors are available, use them
          lightSchemeToUse = lightDynamicFromBuilder;
          darkSchemeToUse = darkDynamicFromBuilder;

          // If a custom seed color is also set, let it override dynamic colors
          if (themeProvider.customSeedColor != null && themeProvider.customSeedColor != Colors.transparent) {
            lightSchemeToUse = ColorScheme.fromSeed(seedColor: themeProvider.customSeedColor!, brightness: Brightness.light);
            darkSchemeToUse = ColorScheme.fromSeed(seedColor: themeProvider.customSeedColor!, brightness: Brightness.dark);
          }
        } else if (themeProvider.customSeedColor != null && themeProvider.customSeedColor != Colors.transparent) {
          // Dynamic colors not yet available, but a custom seed is set
          lightSchemeToUse = themeProvider.lightColorScheme; // Already generated from custom seed
          darkSchemeToUse = themeProvider.darkColorScheme;   // Already generated from custom seed
        } else {
          // No dynamic and no custom seed, use ThemeProvider's default
          // This ensures a valid theme is used while dynamic colors load.
          lightSchemeToUse = ColorScheme.fromSeed(seedColor: themeProvider.defaultSeedColor, brightness: Brightness.light);
          darkSchemeToUse = ColorScheme.fromSeed(seedColor: themeProvider.defaultSeedColor, brightness: Brightness.dark);
        }

        // Apply AMOLED black if needed (only for dark theme)
        if (themeProvider.isDarkMode && themeProvider.isAmoledBlack) {
          darkSchemeToUse = darkSchemeToUse.copyWith(
            background: Colors.black,
            surface: Colors.black,
          );
        }

        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightSchemeToUse,
            fontFamily: appFontFamily, // Apply font family to light theme
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkSchemeToUse,
            fontFamily: appFontFamily, // Apply font family to dark theme
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then((prefs) => prefs.getBool('onboarding_complete') ?? false),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: snapshot.data! ? const HomePage() : const OnboardingScreen(),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        );
      },
    );
  }
}
