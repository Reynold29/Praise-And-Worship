import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around Supabase Auth.
/// Provides sign-in / sign-up / sign-out and caches the current user
/// in-memory so widgets never re-query Supabase on every rebuild.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ── In-memory cache ─────────────────────────────────────────────────────
  User? _cachedUser;

  User? get currentUser {
    _cachedUser ??= _client.auth.currentUser;
    return _cachedUser;
  }

  bool get isLoggedIn => currentUser != null;

  /// Stream of auth state changes (sign-in, sign-out, token refresh …)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Email / Password ─────────────────────────────────────────────────────

  /// Signs in an existing user with e-mail + password.
  /// Returns the [User] on success, throws on failure.
  Future<User> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Sign-in failed: no user returned.');
    _cachedUser = user;
    return user;
  }

  /// Registers a new user with e-mail + password.
  /// Registers a new user, then immediately signs them in so they don't
  /// get stuck waiting for an email confirmation (assumes Supabase project
  /// has "Confirm email" disabled — or falls back gracefully if enabled).
  Future<User> signUpWithEmail(String email, String password) async {
    final signUpResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final signedUpUser = signUpResponse.user;
    if (signedUpUser == null)
      throw Exception('Registration failed. Please try again.');

    // Auto sign-in immediately so the user is logged in without extra steps.
    try {
      final signInResponse = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = signInResponse.user;
      if (user != null) {
        _cachedUser = user;
        return user;
      }
    } catch (_) {
      // If auto sign-in fails (e.g. email confirmation required), surface a
      // clear message rather than a raw exception.
      throw Exception(
          'Account created! Please check your email to confirm your address, then sign in.');
    }
    _cachedUser = signedUpUser;
    return signedUpUser;
  }

  // ── Google OAuth ─────────────────────────────────────────────────────────

  /// Initiates Google OAuth via Supabase.
  /// On mobile this opens a Chrome Custom Tab / Safari modal.
  /// The auth state change stream will fire once the user is returned.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.worshipcompanion://login-callback',
    );
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
    _cachedUser = null;
  }

  // ── Invalidate cache (call after listening to auth state changes) ─────────
  void invalidateCache() {
    _cachedUser = _client.auth.currentUser;
  }
}
