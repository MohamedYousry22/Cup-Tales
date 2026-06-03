import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/auth_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/local_storage/hive_service.dart';
import '../../data/profile_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final ProfileService _profileService;
  final HiveService _hive = di.sl<HiveService>();

  /// Completer that resolves once the initial auth state (session restore) is confirmed.
  /// Used by SplashCubit to avoid navigating before we know if the user is logged in.
  final Completer<void> initialAuthReady = Completer<void>();

  AuthCubit({
    required AuthService authService,
    required ProfileService profileService,
  })  : _authService = authService,
        _profileService = profileService,
        super(AuthInitial()) {
    // Defer Supabase listener until after Supabase.initialize() completes.
    di.appReady.then((_) => _initAuthStateListener());
  }

  bool _isInitialStateHandled = false;
  bool _isGoogleSignInInProgress = false; // Lock to ignore signedOut during Google account switch
  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _initAuthStateListener() {
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (kDebugMode) {
        debugPrint(
            '[AuthCubit] event: $event  session: ${session != null ? "present" : "null"}');
      }

      if (event == supabase.AuthChangeEvent.initialSession) {
        // Supabase has restored the persisted session (or confirmed no session).
        // This is the ONLY reliable signal for "is the user logged in at startup".
        _isInitialStateHandled = true;
        if (session != null) {
          // Fetch and cache the full profile data on startup
          try {
            final profile = await _profileService.getProfile(session.user.id);
            if (profile != null) {
              _hive.profileBox.put('current_user', profile);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('[AuthCubit] profile fetch on startup failed: $e');
          }

          try {
            final role = await _profileService.getUserRole();
            emit(AuthAuthenticated(isAdmin: role == 'admin'));
          } catch (e) {
            if (kDebugMode) debugPrint('[AuthCubit] role fetch failed: $e');
            emit(const AuthAuthenticated(isAdmin: false));
          }
        } else {
          emit(AuthUnauthenticated());
        }
        if (!initialAuthReady.isCompleted) initialAuthReady.complete();
      }
      if (event == supabase.AuthChangeEvent.signedIn &&
          session != null &&
          _isInitialStateHandled) {
        // Explicit sign-in after startup (login form, Google OAuth redirect).
        final user = session.user;
        if (kDebugMode) debugPrint('[AuthCubit] signed in: ${user.email}');

        try {
          await _authService.upsertUserProfile(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'] as String?,
            phone: user.userMetadata?['phone'] as String?,
          );

          // Fetch and cache the full profile data
          final profile = await _profileService.getProfile(user.id);
          if (profile != null) {
            _hive.profileBox.put('current_user', profile);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[AuthCubit] upsert/cache failed silently: $e');
          }
        }

        try {
          final role = await _profileService.getUserRole();
          emit(AuthAuthenticated(isAdmin: role == 'admin'));
        } catch (e) {
          emit(const AuthAuthenticated(isAdmin: false));
        }
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _isInitialStateHandled = true;
        // Ignore signedOut if it was triggered by our own Google account-picker reset.
        // Without this guard, googleSignIn.signOut() causes a ghost navigation to LoginPage.
        if (_isGoogleSignInInProgress) {
          if (kDebugMode) debugPrint('[AuthCubit] signedOut ignored — Google Sign-In in progress');
          return;
        }
        if (kDebugMode) debugPrint('[AuthCubit] signed out');
        emit(AuthUnauthenticated());
      } else if (event == supabase.AuthChangeEvent.passwordRecovery) {
        _isInitialStateHandled = true;
        if (kDebugMode) debugPrint('[AuthCubit] password recovery');
        emit(AuthPasswordRecovery());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ─── App Start ───────────────────────────────────────────────────────────────
  // Session detection is driven entirely by _initAuthStateListener above.
  // onAppStart() emits AuthLoading so AuthGate shows a spinner immediately,
  // and adds a 5-second escape hatch in case the stream never fires.
  void onAppStart() {
    if (!_isInitialStateHandled) {
      emit(AuthLoading());
    }

    // Safety fallback: if no auth event arrives within 5 seconds, default to
    // unauthenticated. This handles edge cases like network timeouts.
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialStateHandled && state is AuthLoading) {
        _isInitialStateHandled = true;
        if (kDebugMode) debugPrint('[AuthCubit] timeout → AuthUnauthenticated');
        emit(AuthUnauthenticated());
        if (!initialAuthReady.isCompleted) initialAuthReady.complete();
      }
    });
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      emit(const AuthError('Please enter a valid email'));
      return;
    }
    if (password.length < 6) {
      emit(const AuthError('Password must be at least 6 characters'));
      return;
    }

    emit(AuthLoading());
    try {
      await _authService.signIn(email: email, password: password);
      // Auth listener handles emission of AuthAuthenticated
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (fullName.trim().isEmpty) {
      emit(const AuthError('Please enter your full name'));
      return;
    }
    if (phone.trim().isEmpty) {
      emit(const AuthError('Please enter your phone number'));
      return;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      emit(const AuthError('Please enter a valid email'));
      return;
    }
    if (password.length < 6) {
      emit(const AuthError('Password must be at least 6 characters'));
      return;
    }

    emit(AuthLoading());
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      // When "Confirm email" is DISABLED in Supabase, signUp returns an active
      // session immediately. The auth stream listener will fire a signedIn event
      // and emit AuthAuthenticated automatically.
      //
      // However, as a safety net, if the stream has already marked the initial
      // state as handled (app is running), we manually trigger the authenticated
      // state in case the signedIn event arrives before we return here.
      if (response.session != null && _isInitialStateHandled) {
        try {
          final role = await _profileService.getUserRole();
          emit(AuthAuthenticated(isAdmin: role == 'admin'));
        } catch (_) {
          emit(const AuthAuthenticated(isAdmin: false));
        }
      }
      // If session is null, email confirmation is still ON in the dashboard —
      // show a helpful error so the developer knows what to fix.
      else if (response.session == null && response.user != null) {
        emit(const AuthError(
            'Account created — but email confirmation is still enabled in your Supabase dashboard. Please disable it to allow instant login.'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Google Login ─────────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    _isGoogleSignInInProgress = true;
    try {
      await _authService.signInWithGoogle();

      // ── Fallback: manually confirm state ────────────────────────────────────
      // signInWithIdToken is a direct token exchange — it does NOT reliably fire
      // a stream 'signedIn' event. Without this, the UI stays stuck on AuthLoading.
      final session =
          supabase.Supabase.instance.client.auth.currentSession;
      if (session != null) {
        if (kDebugMode) {
          debugPrint('[AuthCubit] Google Sign-In success — manually emitting AuthAuthenticated');
        }
        try {
          final role = await _profileService.getUserRole();
          emit(AuthAuthenticated(isAdmin: role == 'admin'));
        } catch (_) {
          emit(const AuthAuthenticated(isAdmin: false));
        }
      } else {
        // Session missing — something went wrong silently
        emit(const AuthError('Google Sign-In failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    } finally {
      // Small trailing delay to ensure all stream events from the account picker reset are swallowed.
      Future.delayed(const Duration(milliseconds: 500), () {
        _isGoogleSignInInProgress = false;
      });
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────────

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(const AuthError('Password reset email sent'));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────────

  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await _authService.updatePassword(newPassword);
      emit(const AuthError('Password updated successfully. Please login.'));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
