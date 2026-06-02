import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_success_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/profile/presentation/pages/personal_info_page.dart';
import '../../features/profile/presentation/pages/notifications_settings_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/profile/presentation/pages/branches_page.dart';
import '../../features/checkout/presentation/pages/payment_failure_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String products = '/products';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailure = '/payment-failure';
  static const String resetPassword = '/reset-password';
  static const String personalInfo = '/personal-info';
  static const String notifications = '/notifications';
  static const String privacyPolicy = '/privacy-policy';
  static const String orders = '/orders';
  static const String branches = '/branches';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    debugPrint('\n[AppRouter] generateRoute -> ${settings.name}');
    final routeName = settings.name ?? '';

    // Handle Supabase OAuth callback deep-links (e.g. /?code=...)
    // Route to AuthGate which picks up the new session from the auth stream.
    if (routeName.contains('code=')) {
      debugPrint(
          '[AppRouter] Caught Supabase OAuth Deep Link! Yielding AuthGate.');
      return MaterialPageRoute(builder: (_) => const AuthGate());
    }

    switch (settings.name) {
      case splash:
        debugPrint('[AppRouter] Yielding AnimatedSplashPage');
        return MaterialPageRoute(builder: (_) => const AnimatedSplashPage());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case home:
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case productDetails:
        if (settings.arguments is! ProductEntity) {
          debugPrint(
              '[AppRouter] productDetails arguments is null or invalid. Redirecting to AuthGate.');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AuthGate(),
          );
        }
        final product = settings.arguments as ProductEntity;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProductDetailsPage(product: product),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartPage());

      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());

      case paymentSuccess:
        final orderId = settings.arguments as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaymentSuccessPage(orderId: orderId),
        );

      case paymentFailure:
        return MaterialPageRoute(builder: (_) => const PaymentFailurePage());

      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());

      case personalInfo:
        return MaterialPageRoute(builder: (_) => const PersonalInfoPage());

      case notifications:
        return MaterialPageRoute(
            builder: (_) => const NotificationsSettingsPage());

      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());

      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersPage());

      case branches:
        return MaterialPageRoute(builder: (_) => const BranchesPage());

      default:
        return null; // Triggers onUnknownRoute in MaterialApp
    }
  }
}
