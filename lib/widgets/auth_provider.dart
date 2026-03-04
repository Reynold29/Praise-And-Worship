import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'favorite_provider.dart';

/// Listens to Supabase auth state events and propagates them to [FavoriteProvider].
/// Also exposes logged-in user info to the widget tree.
class AuthProvider with ChangeNotifier {
  final FavoriteProvider _favoriteProvider;

  User? _user;
  bool _loading = false;
  String? _error;

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
  bool get loading => _loading;
  String? get error => _error;

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await AuthService.instance.signInWithEmail(email, password);
      // _onAuthStateChange will pick up the new user event from the stream
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await AuthService.instance.signUpWithEmail(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await AuthService.instance.signInWithGoogle();
      // Auth state change fires when the OAuth redirect completes
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.instance.signOut();
      await _favoriteProvider.switchToLocal();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
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
      // Fresh sign-in: load cloud favourites into the provider.
      // The sync dialog (shown from UI) will handle the local→cloud merge.
      await _favoriteProvider.switchToCloud(newUser.id);
    } else if (newUser == null && previousUser != null) {
      // Sign-out
      await _favoriteProvider.switchToLocal();
    }

    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
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
