import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'favorite_provider.dart';

/// Which action is currently in progress (for per-button loading indicators).
enum AuthLoadingSource { none, google, apple, email, delete }

/// Listens to Supabase auth state events and propagates them to [FavoriteProvider].
/// Also exposes logged-in user info to the widget tree.
class AuthProvider with ChangeNotifier {
  final FavoriteProvider _favoriteProvider;

  User? _user;
  AuthLoadingSource _loadingSource = AuthLoadingSource.none;
  String? _error;

  /// Optional callback invoked after a successful sign-in/up.
  VoidCallback? onLoginSuccess;

  AuthProvider(this._favoriteProvider) {
    // Populate from cached session (handles cold-start when user was already
    // signed in from a previous run).
    _user = AuthService.instance.currentUser;

    // Subscribe to ongoing auth state changes.
    AuthService.instance.authStateChanges.listen(_onAuthStateChange);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isLoggedIn => _user != null;
  User? get currentUser => _user;
  String? get email => _user?.email;
  String? get displayName =>
      _user?.userMetadata?['full_name'] as String? ??
      _user?.userMetadata?['name'] as String? ??
      _user?.email?.split('@').first;

  /// True only if any auth action is in progress.
  bool get loading => _loadingSource != AuthLoadingSource.none;

  /// True only while Google sign-in is in progress.
  bool get loadingGoogle => _loadingSource == AuthLoadingSource.google;

  /// True only while Apple sign-in is in progress.
  bool get loadingApple => _loadingSource == AuthLoadingSource.apple;

  /// True only while email sign-in/up is in progress.
  bool get loadingEmail => _loadingSource == AuthLoadingSource.email;

  /// True only while account deletion is in progress.
  bool get loadingDelete => _loadingSource == AuthLoadingSource.delete;

  String? get error => _error;

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(AuthLoadingSource.email);
    try {
      await AuthService.instance.signInWithEmail(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _setLoading(AuthLoadingSource.email);
    try {
      await AuthService.instance.signUpWithEmail(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(AuthLoadingSource.google);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading(AuthLoadingSource.apple);
    try {
      await AuthService.instance.signInWithApple();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  Future<void> signOut() async {
    _setLoading(AuthLoadingSource.delete);
    try {
      await AuthService.instance.signOut();
      await _favoriteProvider.switchToLocal();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(AuthLoadingSource.delete);
    try {
      try {
        await AuthService.instance.deleteAccount();
      } catch (rpcError) {
        // RPC not created yet — still sign out locally.
      }
      await AuthService.instance.signOut();
      await _favoriteProvider.switchToLocal();
      // Clear all local profile data so the avatar / name vanish immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('fullname');
      await prefs.remove('profile_image_path');
      await prefs.remove('google_avatar_url');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(AuthLoadingSource.none);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onAuthStateChange(AuthState state) async {
    final newUser = state.session?.user;
    final previousUser = _user;
    _user = newUser;
    AuthService.instance.invalidateCache();

    if (newUser != null && previousUser == null) {
      // Fresh sign-in — switch to cloud favourites
      await _favoriteProvider.switchToCloud(newUser.id);

      // Auto-populate profile from Google / Apple metadata on first login
      await _syncProfileFromProvider(newUser);

      // Fire the success callback so the auth screen can navigate away
      onLoginSuccess?.call();
    } else if (newUser == null && previousUser != null) {
      // Sign-out
      await _favoriteProvider.switchToLocal();
    }

    notifyListeners();
  }

  /// Reads provider metadata (Google: full_name, avatar_url) and saves to
  /// SharedPreferences + Supabase if the local username is not yet set.
  Future<void> _syncProfileFromProvider(User user) async {
    try {
      final meta = user.userMetadata ?? {};
      final fullName =
          (meta['full_name'] as String? ?? meta['name'] as String? ?? '')
              .trim();
      final firstName = fullName.isNotEmpty
          ? fullName.split(' ').first.trim()
          : (user.email?.split('@').first ?? '');
      final avatarUrl =
          (meta['avatar_url'] as String? ?? meta['picture'] as String? ?? '')
              .trim();

      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('username') ?? '';

      // Only auto-fill if the user hasn't already set a username themselves
      if (storedUsername.isEmpty && firstName.isNotEmpty) {
        await prefs.setString('username', firstName);
      }
      if ((prefs.getString('fullname') ?? '').isEmpty && fullName.isNotEmpty) {
        await prefs.setString('fullname', fullName);
      }
      if (avatarUrl.isNotEmpty) {
        await prefs.setString('google_avatar_url', avatarUrl);
      }

      // Upsert to Supabase user_profiles
      if (storedUsername.isEmpty && firstName.isNotEmpty) {
        await AuthService.instance.upsertProfile(
          username: firstName,
          fullName: fullName,
        );
      }
    } catch (_) {
      // Non-critical — skip silently
    }
  }

  void _setLoading(AuthLoadingSource source) {
    _loadingSource = source;
    notifyListeners();
  }

  void _setError(String raw) {
    // Supabase throws AuthApiException(message: ..., statusCode: ..., code: ...)
    // Extract just the human-readable message from the raw exception string.
    String msg = raw;

    // Strip leading "Exception: " wrapper added by our own rethrows
    msg = msg.replaceFirst('Exception: ', '');

    // Parse AuthApiException format
    final msgMatch = RegExp(r'message:\s*([^,)]+)').firstMatch(msg);
    if (msgMatch != null) {
      msg = msgMatch.group(1)?.trim() ?? msg;
    }

    // Map common Supabase error messages to friendlier text
    final lower = msg.toLowerCase();
    if (lower.contains('user already registered') ||
        lower.contains('user_already_exists')) {
      msg =
          'An account with this email already exists. Try signing in instead.';
    } else if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      msg = 'Incorrect email or password. Please try again.';
    } else if (lower.contains('email not confirmed')) {
      msg = 'Please confirm your email address before signing in.';
    } else if (lower.contains('rate limit') ||
        lower.contains('too_many_requests')) {
      msg = 'Too many attempts. Please wait a moment and try again.';
    }

    _error = msg;
    notifyListeners();
  }
}
