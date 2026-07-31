import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

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
        // No emailRedirectTo — we rely on "Confirm email" being OFF in the
        // Supabase dashboard so the session is created immediately after signUp.
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
      if (defaultTargetPlatform != TargetPlatform.android) {
        throw const AuthException(
          'Google Sign-In is available on Android only.',
        );
      }
      if (kDebugMode) {
        debugPrint('AuthService: Starting Native Google Sign-In');
      }

      // Android reads its package/certificate mapping from google-services.json.
      // Supabase validates the token against the Web OAuth client ID.
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? SupabaseConfig.googleIosClientId
            : null,
        serverClientId: SupabaseConfig.googleWebClientId,
      );

      // Clear any cached Google session so the account picker always appears.
      await googleSignIn.signOut();

      // Trigger the native account picker.
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled');
      }

      // Exchange Google's native tokens for a Supabase session.
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Could not retrieve Google ID Token.');
      }
      if (accessToken == null) {
        throw const AuthException('Could not retrieve Google access token.');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (kDebugMode) {
        debugPrint('AuthService: Native Google Sign-In successful');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'AuthService: AuthException during Google Sign-In: ${e.message}',
        );
      }
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      debugPrint('AuthService: Unexpected error during Google Sign-In: $e');
      throw Exception('Google Sign-In error: ${e.toString()}');
    }
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
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e.message));
    } catch (e) {
      throw Exception('Failed to update password.');
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // Silently disconnect any Google session (fire-and-forget — not all users use Google)
      GoogleSignIn().signOut().ignore();
      // Clear Supabase session
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed.');
    }
  }

  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No account is currently signed in.');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final googleSignIn = GoogleSignIn(
          serverClientId: SupabaseConfig.googleWebClientId,
        );
        await googleSignIn.disconnect();
      } catch (_) {
        // Email/password users do not have a Google connection to revoke.
      }
    }

    try {
      await _client.rpc('delete_my_account');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Account deletion failed. Please try again.');
    }

    // The database function removes the auth user, so Supabase may report that
    // the server-side session no longer exists. Local cleanup is still needed,
    // but that expected response must not turn a successful deletion into an
    // error in the UI.
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Account deletion already succeeded on the server.
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
