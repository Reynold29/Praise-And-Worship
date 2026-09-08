import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
import 'services/supabase_url_resolver.dart';
import 'package:inditrans/inditrans.dart' as inditrans;
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/widgets/playlist_provider.dart';
import 'utils/app_logger.dart';
import 'package:app_links/app_links.dart';
import 'services/qr_router_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch unhandled platform errors (e.g. Supabase.onResumed null crash
  // that fires when returning from OAuth browser) and log instead of crash.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('App', 'Unhandled platform error', error);
    return true;
  };

  // Initialize inditrans for transliteration support
  await inditrans.init();

  // Defensive: Track if Supabase is initialized
  bool supabaseInitialized = false;

  // Try to load .env file, but don't fail if it doesn't exist
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    AppLogger.w('App', 'Could not load .env file: $e');
  }

  // Try to initialize Supabase, but don't block if it fails
  try {
    final primaryUrl = dotenv.env['SUPABASE_URL'];
    final fallbackUrl = dotenv.env['SUPABASE_URL_FALLBACK'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (primaryUrl != null && supabaseAnonKey != null) {
      // Resolve best reachable URL — 2.5 s TCP probe per candidate.
      // Users on working connections hit Supabase with zero extra delay.
      // Blocked users wait ≤2.5 s then fall through to JioBase.
      final resolvedUrl = fallbackUrl != null
          ? await SupabaseUrlResolver.instance.resolve(
              primary: primaryUrl,
              fallback: fallbackUrl,
            )
          : primaryUrl;

      await Supabase.initialize(
        url: resolvedUrl,
        anonKey: supabaseAnonKey,
      );
      supabaseInitialized = true;
      AppLogger.d('App', 'Supabase initialized (url: $resolvedUrl)');
    } else {
      AppLogger.w('App', 'Supabase credentials not found in .env');
    }
  } catch (e) {
    AppLogger.e('App', 'Supabase initialization failed', e);
    // Proceed without Supabase; local DB will be used
  }

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? false;

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize FavoriteProvider and load favorites
  final favoriteProvider = FavoriteProvider();
  final playlistProvider = PlaylistProvider();

  // Restore cloud session if user was already logged in
  if (supabaseInitialized) {
    try {
      final existingUser = Supabase.instance.client.auth.currentUser;
      if (existingUser != null) {
        // Load cloud favourites without blocking; UI shows loading state
        favoriteProvider.switchToCloud(existingUser.id).catchError((e) {
          AppLogger.e('App', 'Failed to restore cloud favourites', e);
        });
        playlistProvider.switchToCloud(existingUser.id).catchError((e) {
          AppLogger.e('App', 'Failed to restore cloud playlists', e);
        });
      }
    } catch (e) {
      AppLogger.e('App', 'Session restore error', e);
    }
  }

  // Create AuthProvider (depends on favoriteProvider)
  final authProvider = AuthProvider(favoriteProvider, playlistProvider);

  // Fetch remote app config (social_login_enabled, etc.)
  // This is non-blocking in that we await it before runApp but it has a
  // 6-second timeout and falls back to safe defaults on failure.
  final appConfigProvider = AppConfigProvider();
  if (supabaseInitialized) {
    await appConfigProvider.load();
  }

  // --- Sync local DB from Supabase if online and Supabase is initialized ---
  // Make this non-blocking so app can start even without internet
  if (supabaseInitialized) {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final online = connectivityResult.isEmpty ||
          !(connectivityResult.length == 1 &&
              connectivityResult.first == ConnectivityResult.none);
      if (online) {
        // Run sync in background without blocking app startup
        LocalDatabaseService.instance.syncFromSupabase().catchError((e) {
          AppLogger.e('App', 'Background English sync failed', e);
        });
        LocalDatabaseService.instance.syncKannadaFromSupabase().then((_) {
          LocalDatabaseService.instance.removeUnwantedKannadaSongs();
        }).catchError((e) {
          AppLogger.e('App', 'Background Kannada sync failed', e);
        });
        LocalDatabaseService.instance.syncOtherFromSupabase().catchError((e) {
          AppLogger.e('App', 'Background Other sync failed', e);
        });

        // Trigger periodic 3-day full sync check
        LocalDatabaseService.instance.syncAllCategories().catchError((e) {
          AppLogger.e('App', 'Periodic full sync check failed', e);
        });
      }
      RealtimeSyncService.instance.startListening();
    } catch (e) {
      AppLogger.e('App', 'Connectivity check or sync failed', e);
      // Continue without sync
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: favoriteProvider),
        ChangeNotifierProvider.value(value: playlistProvider),
        ChangeNotifierProvider.value(value: appConfigProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MyApp(
          showOnboarding: showOnboarding,
          supabaseInitialized: supabaseInitialized),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  final bool supabaseInitialized;

  const MyApp(
      {super.key,
      required this.showOnboarding,
      this.supabaseInitialized = true});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) async {
      final online = result.isEmpty ||
          !(result.length == 1 && result.first == ConnectivityResult.none);
      if (online && widget.supabaseInitialized) {
        await LocalDatabaseService.instance.syncFromSupabase();
        await LocalDatabaseService.instance.syncKannadaFromSupabase();
        await LocalDatabaseService.instance.syncOtherFromSupabase();
        // Also refresh favorites in case they were updated by sync
        if (mounted) {
          Provider.of<FavoriteProvider>(context, listen: false)
              .refreshFavorites();
        }
      }
    });

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Handle initial link (when app is launched from a link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri.toString());
      }
    } catch (e) {
      AppLogger.e('App', 'Failed to get initial link', e);
    }

    // 2. Listen to incoming links (when app is already running)
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri.toString());
    }, onError: (err) {
      AppLogger.e('App', 'Deep link stream error', err);
    });

    // 3. Check clipboard for "Deferred Deep Link" (Post-install)
    _checkClipboardForDeepLink();
  }

  Future<void> _checkClipboardForDeepLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null &&
          (text.contains('projects.reyziehomelab.com/worshipcompanion/song') ||
              text.contains(
                  'projects.reyziehomelab.com/worshipcompanion/lyrics') ||
              text.contains(
                  'projects.reyziehomelab.com/worshipcompanion/playlist'))) {
        AppLogger.d('App', 'Found deferred deep link in clipboard: $text');
        // Wait for Navigator
        _handleLink(text);
        // Clear clipboard to avoid re-opening on next launch
        // We only clear if it's OUR specific link
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (e) {
      AppLogger.e('App', 'Clipboard check failed', e);
    }
  }

  bool _isAuthCallback(Uri uri) {
    return uri.scheme == 'io.supabase.worshipcompanion' ||
        uri.host.toLowerCase() == 'login-callback';
  }

  Future<void> _handleLink(String url) async {
    AppLogger.d('App', 'Processing deep link: $url');
    final uri = Uri.tryParse(url);
    // OAuth redirects must not go through the QR router (that showed
    // "Invalid QR Code" and never completed sign-in). supabase_flutter
    // exchanges the PKCE code from its own app_links subscription.
    if (uri != null && _isAuthCallback(uri)) {
      AppLogger.d('App', 'OAuth callback — skipping QR router');
      return;
    }

    // Wait for Navigator to be ready if needed
    int retries = 0;
    while (navigatorKey.currentContext == null && retries < 15) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    if (mounted) {
      QRRouterService.instance.handleUrl(
        navigatorKey.currentContext ?? context,
        url,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const String appFontFamily = 'ProductSans';

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamicFromBuilder,
          ColorScheme? darkDynamicFromBuilder) {
        ColorScheme lightSchemeToUse;
        ColorScheme darkSchemeToUse;
        final variant = themeProvider.isExpressive
            ? DynamicSchemeVariant.expressive
            : DynamicSchemeVariant.tonalSpot;

        if (!themeProvider.isExpressive &&
            lightDynamicFromBuilder != null &&
            darkDynamicFromBuilder != null) {
          lightSchemeToUse = lightDynamicFromBuilder;
          darkSchemeToUse = darkDynamicFromBuilder;
        } else if (themeProvider.isExpressive) {
          lightSchemeToUse = themeProvider.lightColorScheme;
          darkSchemeToUse = themeProvider.darkColorScheme;
        } else {
          lightSchemeToUse = ColorScheme.fromSeed(
            seedColor: themeProvider.defaultSeedColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: variant,
          );
          darkSchemeToUse = ColorScheme.fromSeed(
            seedColor: themeProvider.defaultSeedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: variant,
          );
        }

        if (themeProvider.isAmoledBlack) {
          darkSchemeToUse = darkSchemeToUse.copyWith(
            surface: Colors.black,
            surfaceContainerLowest: Colors.black,
          );
        }

        ThemeData themed(ColorScheme scheme) {
          return ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            fontFamily: appFontFamily,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }

        final lightTheme = themed(lightSchemeToUse);
        final darkTheme = themed(darkSchemeToUse);
        final m3eData = themeProvider.isDarkMode
            ? M3EThemeData.fromMaterial(darkTheme)
            : M3EThemeData.fromMaterial(lightTheme);

        Widget home = FutureBuilder<bool>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getBool('onboarding_complete') ?? false),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                reverseDuration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    snappySwitcherTransition(animation, child),
                child: snapshot.data!
                    ? const HomePage()
                    : const OnboardingScreen(),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );

        return M3EMaterialApp(
          navigatorKey: navigatorKey,
          title: 'Worship Companion',
          debugShowCheckedModeBanner: false,
          fontFamily: appFontFamily,
          data: m3eData,
          theme: lightTheme,
          darkTheme: darkTheme,
          autoTheming: false,
          dynamicColoring: !themeProvider.isExpressive,
          initialTheme: themeProvider.isDarkMode
              ? Brightness.dark
              : Brightness.light,
          appBuilder: (context, child) {
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
            final userScale = mq.textScaler.scale(1);
            final combinedScale = (userScale * baseScale).clamp(0.85, 1.15);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(combinedScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: home,
        );
      },
    );
  }
}

