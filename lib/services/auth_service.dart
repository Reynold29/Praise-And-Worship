import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ── Apple Sign-In (native iOS/macOS) ─────────────────────────────────────

  /// Native Apple Sign-In using the sign_in_with_apple package.
  ///
  /// Flow:
  ///   1. Generate a cryptographic nonce (random bytes → base64url).
  ///   2. Hash it with SHA-256 and pass the hex digest to Apple.
  ///   3. Apple returns an identityToken + the raw nonce.
  ///   4. Pass both to Supabase.signInWithIdToken — this validates the token
  ///      server-side (no browser / PKCE redirect needed).
  Future<void> signInWithApple() async {
    // Generate a secure random nonce
    final rawNonce = _generateNonce();
    final hashedNonce = sha256
        .convert(utf8.encode(rawNonce))
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // Show native Apple Sign-In sheet
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Apple Sign-In: no identity token.');

    // Sign in to Supabase using the ID token + raw nonce
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    _cachedUser = response.user;
  }

  /// Generates a cryptographically random base64url-encoded string.
  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
    _cachedUser = null;
  }

  // ── Delete account ────────────────────────────────────────────────────────

  /// Calls the `delete_user_account` Supabase RPC to delete all user data
  /// (favorites, profile) and removes the auth user.
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user_account');
    _cachedUser = null;
  }

  // ── User profile sync ─────────────────────────────────────────────────────

  /// Syncs local profile info to Supabase `user_profiles` table.
  Future<void> upsertProfile({String? username, String? fullName}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('user_profiles').upsert({
      'id': uid,
      if (username != null) 'username': username,
      if (fullName != null) 'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  /// Fetches the user's profile from Supabase.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows =
        await _client.from('user_profiles').select().eq('id', uid).limit(1);
    final list = rows as List;
    return list.isNotEmpty ? list.first as Map<String, dynamic> : null;
  }

  // ── Invalidate cache (call after listening to auth state changes) ─────────
  void invalidateCache() {
    _cachedUser = _client.auth.currentUser;
  }
}
