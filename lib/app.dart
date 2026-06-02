import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_language.dart';
import 'core/localization/language_cubit.dart';
import 'core/localization/app_localizations.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/orders/presentation/cubit/orders_cubit.dart';
import 'core/widgets/app_background.dart';
import 'core/di/injection_container.dart' as di;

// Cached theme — never rebuilt, computed once
final ThemeData _cachedTheme = AppTheme.lightTheme;

class CupTalesApp extends StatefulWidget {
  const CupTalesApp({super.key});
  @override
  State<CupTalesApp> createState() => _CupTalesAppState();
}

class _CupTalesAppState extends State<CupTalesApp> {
  // Cubits — created synchronously (constructors are cheap).
  // They defer all I/O internally via di.appReady, so construction is instant.
  late final LanguageCubit _languageCubit = di.sl<LanguageCubit>();
  late final AuthCubit _authCubit = di.sl<AuthCubit>();
  late final CartCubit _cartCubit = di.sl<CartCubit>();
  late final OrdersCubit _ordersCubit = di.sl<OrdersCubit>();

  Locale _locale = const Locale('ar');

  @override
  void initState() {
    super.initState();
    debugPrint('[App] initState');

    // Start cubit work — all deferred via di.appReady, zero cost right now.
    _languageCubit.load();
    _authCubit.onAppStart();
    di.appReady.then((_) {
      if (mounted) _cartCubit.loadCart();
    });

    // Listen for language changes to update MaterialApp.locale
    _languageCubit.stream.listen((state) {
      if (mounted) {
        setState(() {
          _locale = state.language == AppLanguage.ar
              ? const Locale('ar')
              : const Locale('en');
        });
      }
    });
  }

  @override
  void dispose() {
    _languageCubit.close();
    _authCubit.close();
    _cartCubit.close();
    _ordersCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>.value(value: _languageCubit),
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<CartCubit>.value(value: _cartCubit),
        BlocProvider<OrdersCubit>.value(value: _ordersCubit),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: _cachedTheme,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return AppBackground(child: child ?? const SizedBox.shrink());
        },
        navigatorObservers: [RouteTracker()],
        supportedLocales: const [Locale('en', ''), Locale('ar', '')],
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
        onUnknownRoute: (settings) {
          if (kDebugMode) {
            debugPrint('[Router] Unknown route: ${settings.name} → AuthGate');
          }
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AuthGate(),
          );
        },
      ),
    );
  }
}
