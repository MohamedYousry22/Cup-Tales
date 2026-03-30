import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/services/paymob_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/auth/data/profile_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/branch_service.dart';
import '../../../../core/services/promo_code_service.dart';
import '../../../../core/models/branch.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit _cartCubit;
  final PaymobService _paymobService;
  final AuthService _authService;
  final ProfileService _profileService;
  final OrderService _orderService;
  final BranchService _branchService;
  final PromoCodeService _promoCodeService;

  CheckoutCubit(
    this._cartCubit,
    this._paymobService,
    this._authService,
    this._profileService,
    this._orderService,
    this._branchService,
    this._promoCodeService,
  ) : super(CheckoutInitial(
          branches: appBranches,
          selectedBranch: appBranches.isNotEmpty ? appBranches.first : null,
        )) {
    loadBranches();
  }

  static const int _visaIntegrationId = 5577397;
  static const int _walletIntegrationId = 5584969;

  // ── Branch loading ──────────────────────────────────────────────────────────

  void loadBranches() async {
    final branches = await _branchService.getBranches();
    if (state is CheckoutInitial) {
      final s = state as CheckoutInitial;
      emit(s.copyWith(
        branches: branches,
        selectedBranch: s.selectedBranch ?? (branches.isNotEmpty ? branches.first : null),
      ));
    }
  }

  // ── Selections ──────────────────────────────────────────────────────────────

  void selectPaymentMethod(String method) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedMethod: method));
    }
  }

  void selectBranch(Branch branch) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedBranch: branch));
    }
  }

  // ── Promo Code ──────────────────────────────────────────────────────────────

  Future<void> applyPromoCode(String code) async {
    if (code.trim().isEmpty) return;
    if (state is! CheckoutInitial) return;

    final currentState = state as CheckoutInitial;

    // Get current subtotal from cart
    double subtotal = 0.0;
    if (_cartCubit.state is CartLoaded) {
      subtotal = (_cartCubit.state as CartLoaded).subtotal;
    }

    // Emit transient loading state (keeps the page intact)
    emit(CheckoutValidatingPromo());

    final result = await _promoCodeService.validate(code, subtotal);

    if (result is PromoValid) {
      emit(currentState.copyWith(
        appliedPromo: result.code,
        promoDiscount: result.discountAmount,
        promoError: null,
      ));
    } else if (result is PromoInvalid) {
      emit(currentState.copyWith(
        appliedPromo: null,
        promoDiscount: 0.0,
        promoError: result.arabicReason,
      ));
    }
  }

  void removePromoCode() {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(
        appliedPromo: null,
        promoDiscount: 0.0,
        promoError: null,
      ));
    }
  }

  // ── Payment Processing ──────────────────────────────────────────────────────

  Future<void> processPayment({String? walletNumber}) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;

    final String selectedMethod = currentState.selectedMethod;
    final double promoDiscount = currentState.promoDiscount;
    final String? appliedPromo = currentState.appliedPromo;

    emit(CheckoutProcessing());

    try {
      if (selectedMethod == 'Visa' || selectedMethod == 'Wallet') {
        // 1. Get current user
        final user = _authService.currentUser;
        if (user == null) throw Exception('User not logged in');

        // 2. Fetch profile for billing data
        final profile = await _profileService.getProfile(user.id);
        final String fullName = profile?['name'] as String? ?? 'NA';
        final List<String> nameParts = fullName.split(' ');

        String phoneNumber = walletNumber ?? (profile?['phone'] as String? ?? 'NA');

        // Ensure phone number exists for wallets
        if (selectedMethod == 'Wallet' && (phoneNumber == 'NA' || phoneNumber.trim().isEmpty)) {
          throw Exception('Phone number is required for Mobile Wallet transactions. Please enter a valid wallet number.');
        }

        final Map<String, String> billingData = {
          'first_name': nameParts.isNotEmpty ? nameParts.first : 'NA',
          'last_name': nameParts.length > 1 ? nameParts.last : 'NA',
          'email': user.email ?? 'NA',
          'phone_number': phoneNumber,
        };

        // 3. Get Cart Total (with promo applied)
        double amount = 0.0;
        if (_cartCubit.state is CartLoaded) {
          final cartState = _cartCubit.state as CartLoaded;
          amount = cartState.subtotal - promoDiscount;
        }

        if (amount <= 0) throw Exception('Invalid order amount');

        // 4. Paymob Flow
        final authToken = await _paymobService.getAuthToken();
        final orderId = await _paymobService.registerOrder(
          authToken: authToken,
          amount: amount,
        );

        final int integrationId =
            selectedMethod == 'Visa' ? _visaIntegrationId : _walletIntegrationId;

        final paymentToken = await _paymobService.getPaymentKey(
          authToken: authToken,
          orderId: orderId,
          amount: amount,
          integrationId: integrationId,
          billingData: billingData,
        );

        // 5. Redirection Flow
        String redirectionUrl = '';

        if (selectedMethod == 'Visa') {
          const int iframeId = 1014745;
          print('DEBUG: Visa selected, using Iframe URL ($iframeId)');
          redirectionUrl = 'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentToken';
        } else {
          print('DEBUG: Wallet selected, calling initiatePayment');
          redirectionUrl = await _paymobService.initiatePayment(
            paymentToken: paymentToken,
            phone: phoneNumber,
          );
        }

        print('DEBUG: Final Redirection URL ready: $redirectionUrl');

        if (redirectionUrl.isEmpty) {
          throw Exception('Failed to get redirection URL from Paymob for $selectedMethod.');
        }

        // Stash promo + branch info so savePaidOrder() can recover it
        // from the WebView screen (which is a different widget tree).
        _pendingAppliedPromo = currentState.appliedPromo;
        _pendingPromoDiscount = currentState.promoDiscount;
        _pendingBranchName = currentState.selectedBranch?.nameAr ?? '';

        emit(CheckoutPaymentRedirect(redirectionUrl));
      } else {
        // ── Cash / Cashier flow ──────────────────────────────────────────────
        final String branchName = currentState.selectedBranch?.nameAr ?? '';

        await Future.delayed(const Duration(seconds: 2));
        await _cartCubit.checkout(
          branchName: branchName,
          promoDiscount: promoDiscount,
          appliedPromo: appliedPromo,
        );

        // Increment usage after successful cash order
        if (appliedPromo != null && appliedPromo.isNotEmpty) {
          _promoCodeService.incrementUsage(appliedPromo);
        }

        emit(CheckoutSuccess());
      }
    } catch (e) {
      emit(CheckoutError(e.toString()));
      if (state is! CheckoutInitial) {
        emit(CheckoutInitial(
          selectedMethod: selectedMethod,
          branches: appBranches,
          selectedBranch: currentState.selectedBranch,
          appliedPromo: currentState.appliedPromo,
          promoDiscount: currentState.promoDiscount,
        ));
      }
    }
  }

  // ── Save Paid Order (Visa / Wallet) ─────────────────────────────────────────

  /// Called from the WebView after Paymob confirms success.
  Future<String?> savePaidOrder() async {
    final user = _authService.currentUser;
    if (user == null || _cartCubit.state is! CartLoaded) return null;

    final cartState = _cartCubit.state as CartLoaded;
    final items = cartState.items;
    if (items.isEmpty) return null;

    // Recover promo state: at this point we are in CheckoutPaymentRedirect or
    // a restored CheckoutInitial; we stashed promo in the state before emitting
    // CheckoutPaymentRedirect, so read it back via a stored reference.
    // Since processPayment captured these before emitting, we pass them
    // through the _pendingPromo helpers below.
    final String? appliedPromo = _pendingAppliedPromo;
    final double promoDiscount = _pendingPromoDiscount;

    try {
      final double totalAmount =
          cartState.subtotal - promoDiscount;

      final String branchName = state is CheckoutInitial
          ? ((state as CheckoutInitial).selectedBranch?.nameAr ?? '')
          : _pendingBranchName;

      final response = await _orderService.saveOrder(
        userId: user.id,
        items: items.map((e) => e.toJson()).toList(),
        total: totalAmount,
        status: 'Paid',
        branchName: branchName,
        appliedPromo: appliedPromo,
        promoDiscount: promoDiscount,
      );

      // Increment promo usage
      if (appliedPromo != null && appliedPromo.isNotEmpty) {
        _promoCodeService.incrementUsage(appliedPromo);
      }

      print('DEBUG: Order successfully saved with ID: $response');
      return response;
    } catch (e) {
      print('DEBUG: Error saving order to Supabase: $e');
      rethrow;
    }
  }

  // ── Pending state helpers (bridge CheckoutInitial → WebView) ───────────────
  // These are set just before we redirect to the WebView, and read back in
  // savePaidOrder() which is called from the WebView screen.

  String? _pendingAppliedPromo;
  double _pendingPromoDiscount = 0.0;
  String _pendingBranchName = '';

}
