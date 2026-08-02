import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'core/services/branch_service.dart';
import 'core/config/supabase_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  final t0 = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Firebase and OneSignal are Android-only in this release. iOS intentionally
  // uses Cup Tales email/password authentication and does not expose push
  // settings until APNs is configured in the Apple Developer account.
  if (isAndroid) {
    try {
      // Native Android/iOS startup may already have created the default app from
      // google-services.json / GoogleService-Info.plist.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint('[Startup] Firebase Initialized Successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('[Startup] Firebase already initialized by the native app');
      } else {
        debugPrint('[Startup] Firebase Initialization Error: $e');
      }
    } catch (e) {
      debugPrint('[Startup] Firebase Initialization Error: $e');
    }

    // 2. Initialize OneSignal
    try {
      OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.verbose : OSLogLevel.none,
      );
      await OneSignal.initialize("70034a90-6547-41cc-8791-c310527ea5dd");

      // Debug - helpful for dashboard verification
      // Giving it a 3-second delay to ensure registration is complete after a fresh install
      if (kDebugMode) {
        debugPrint('DEBUG: Delay started (3 seconds to OneSignal ID)');
        Future.delayed(const Duration(seconds: 3), () {
          debugPrint('DEBUG: Delay finished (Fetching OneSignal ID)');
          final sub = OneSignal.User.pushSubscription;
          debugPrint('DEBUG OneSignal optedIn: ${sub.optedIn}');
          debugPrint('DEBUG OneSignal id: ${sub.id}');
          debugPrint('DEBUG OneSignal token: ${sub.token}');
        });
      }

      // Show notifications as banner even when app is open (foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
            'DEBUG: Foreground notification received: ${event.notification.title}');
        event.preventDefault();
        event.notification.display();
      });

      debugPrint('[Startup] OneSignal Initialized');
    } catch (e) {
      debugPrint('[Startup] OneSignal Initialization Error: $e');
    }
  }

  debugPrint('\n======================================================');
  debugPrint('[Startup] FLUTTER ENGINE START / RESTART');
  debugPrint(
      '[Startup] binding ready  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // Track app lifecycle
  AppLifecycleListener(
    onResume: () =>
        debugPrint('[Startup Lifecycle] ON_RESUME (Warm start / Foreground)'),
    onPause: () => debugPrint('[Startup Lifecycle] ON_PAUSE (Background)'),
    onDetach: () => debugPrint('[Startup Lifecycle] ON_DETACH'),
  );

  // 3. Register all DI factories synchronously
  di.registerSync();
  debugPrint(
      '[Startup] registerSync done  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // 4. Show the app immediately
  debugPrint('[Startup] runApp called -> CupTalesApp');
  runApp(const CupTalesApp());
  debugPrint(
      '[Startup] runApp complete  +${DateTime.now().difference(t0).inMilliseconds}ms');

  // ── STEP 3: Heavy async init after the splash has started ──
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      debugPrint('[Startup] starting heavy async init');

      // Supabase must finish before appReady is completed because the auth,
      // cart and orders cubits access Supabase as soon as appReady resolves.
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          timeout: Duration(seconds: 60),
          logLevel: RealtimeLogLevel.info,
        ),
      );
      await di.initAsync();

      debugPrint('[Startup] async init done');

      // Non-critical — fire and forget
      di.sl<NotificationService>().init().ignore();
      di.sl<BranchService>().fetchBranches().ignore();
    });
  });
}
