import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Lazy getter — Supabase.instance is only accessed when a method is called,
  // which is always after Supabase.initialize() has completed via di.appReady.
  SupabaseClient get _client => Supabase.instance.client;

  // ─── Getters ─────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      // Create profile record immediately
      if (response.user != null) {
        await upsertUserProfile(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: fullName,
          phone: phone,
        );
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Sign up failed. Please try again.');
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if email is confirmed
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw const AuthException(
            'Please verify your email before logging in.');
      }

      // Upsert profile to profiles table
      if (response.user != null) {
        await upsertUserProfile(
          id: response.user!.id,
          email: response.user!.email ?? '',
          name: response.user!.userMetadata?['full_name'] as String?,
          phone: response.user!.userMetadata?['phone'] as String?,
        );
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Sign in failed. Please try again.');
    }
  }

  // ─── Google Sign In (Native) ──────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      if (kDebugMode) debugPrint('AuthService: Starting Native Google Sign-In');

      // 1. Generate a secure random string (rawNonce)
      final rawNonce = _generateRandomString(16);


      // 3. Initialize Google Sign-In
      // ⚠️ CRITICAL FIX: serverClientId MUST be the WEB CLIENT ID
      const webClientId =
          '684663003564-7bb83qfvsvr26to8q1ld7vffvu80cgsn.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        // The Android Client ID (from google-services.json) explicitly provided to prevent ApiException 10
        clientId: '684663003564-984dgpmp15anrmrrc4uo2sd8e78d717t.apps.googleusercontent.com',
        // The Web Client ID needed by Supabase for server-side validation and token exchange
        serverClientId: webClientId,
      );

      // 4. Force clear any cached Google session so the account picker always appears
      await googleSignIn.signOut();

      // 5. Trigger native account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled');
      }

      // 5. Get the auth details (IdToken and AccessToken)
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Could not retrieve Google ID Token.');
      }

      // 6. Authenticate with Supabase using the rawNonce
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce: rawNonce,
      );

      if (kDebugMode) debugPrint('AuthService: Native Google Sign-In successful');
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: AuthException during Google Sign-In: ${e.message}');
      }
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      debugPrint('AuthService: Unexpected error during Google Sign-In: $e');
      throw Exception('Google Sign-In error: ${e.toString()}');
    }
  }

  /// Helper to generate a 16-byte random string for the OIDC nonce
  String _generateRandomString([int length = 16]) {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  // ─── Reset Password ───────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-password/',
      );
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Failed to send reset email.');
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Failed to update password.');
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // Disconnect Google session to allow account re-selection on next login
      await GoogleSignIn().signOut();
      // Clear Supabase session
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed.');
    }
  }

  // ─── Profile Upsert ──────────────────────────────────────────────────────────

  Future<void> upsertUserProfile({
    required String id,
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': id,
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (e) {
      debugPrint('AuthService: Profile upsert failed: $e');
    }
  }

  // ─── Error Parsing ────────────────────────────────────────────────────────

  String _parseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists';
    }
    if (lower.contains('id token')) {
      return 'Google Sign-In configuration error';
    }
    return message;
  }
}
