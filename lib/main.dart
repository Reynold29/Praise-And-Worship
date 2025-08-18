import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/screens/home_page.dart';
import 'package:worshipcompanion/screens/onboarding_screen.dart';
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
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

  // Defensive: Track if Supabase is initialized
  bool supabaseInitialized = false;
  
  // Try to load .env file, but don't fail if it doesn't exist
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    // Continue without .env file - app should work offline
  }

  // Try to initialize Supabase, but don't block if it fails
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl != null && supabaseAnonKey != null) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      supabaseInitialized = true;
      print('Supabase initialized successfully');
    } else {
      print('Supabase credentials not found in .env file');
    }
  } catch (e) {
    print('Supabase initialization failed: $e');
    // Proceed without Supabase; local DB will be used
  }

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? false;

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize FavoriteProvider and load favorites
  final favoriteProvider = FavoriteProvider();

  // --- Sync local DB from Supabase if online and Supabase is initialized ---
  // Make this non-blocking so app can start even without internet
  if (supabaseInitialized) {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Run sync in background without blocking app startup
        LocalDatabaseService.instance.syncFromSupabase().catchError((e) {
          print('Background sync failed: $e');
        });
      }
      // Start real-time listener only if Supabase is initialized
      RealtimeSyncService.instance.startListening();
    } catch (e) {
      print('Connectivity check or sync failed: $e');
      // Continue without sync
    }
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
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkSchemeToUse,
            fontFamily: appFontFamily, // Apply font family to dark theme
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final width = mq.size.width;
            double baseScale = 1.0;
            if (width < 340) {
              baseScale = 0.88;
            } else if (width < 360) {
              baseScale = 0.92;
            } else if (width < 400) {
              baseScale = 0.96;
            } else if (width < 440) {
              baseScale = 0.98;
            }
            final userScale = mq.textScaleFactor;
            final combinedScale = (userScale * baseScale).clamp(0.85, 1.15);
            return MediaQuery(
              data: mq.copyWith(textScaleFactor: combinedScale),
              child: child!,
            );
          },
          home: FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then((prefs) => prefs.getBool('onboarding_complete') ?? false),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  reverseDuration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => snappySwitcherTransition(animation, child),
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
