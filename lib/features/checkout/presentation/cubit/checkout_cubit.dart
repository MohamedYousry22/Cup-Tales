import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/services/branch_service.dart';
import '../../../../core/services/promo_code_service.dart';
import '../../../../core/models/branch.dart';
import '../../../../core/local_storage/prefs_service.dart';
import '../../../../core/di/injection_container.dart' as di;

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit _cartCubit;
  final BranchService _branchService;
  final PromoCodeService _promoCodeService;

  CheckoutCubit(
    this._cartCubit,
    this._branchService,
    this._promoCodeService,
  ) : super(CheckoutInitial(
          branches: appBranches,
          selectedBranch: _getInitialBranch(appBranches),
        )) {
    loadBranches();
  }

  static Branch? _getInitialBranch(List<Branch> branches) {
    if (branches.isEmpty) return null;
    try {
      final prefs = di.sl<PrefsService>();
      final savedId = prefs.selectedBranchId;
      if (savedId != null) {
        return branches.firstWhere((b) => b.id == savedId,
            orElse: () => branches.first);
      }
    } catch (_) {}
    return branches.first;
  }

  // ── Branch loading ──────────────────────────────────────────────────────────

  void loadBranches() async {
    final branches = await _branchService.getBranches();
    if (state is CheckoutInitial) {
      final s = state as CheckoutInitial;
      emit(s.copyWith(
        branches: branches,
        selectedBranch:
            s.selectedBranch ?? (branches.isNotEmpty ? branches.first : null),
      ));
    }
  }

  // ── Selections ──────────────────────────────────────────────────────────────

  void selectPaymentMethod(String method) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedMethod: 'Cashier'));
    }
  }

  void selectBranch(Branch branch) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedBranch: branch));
      try {
        di.sl<PrefsService>().setSelectedBranchId(branch.id);
      } catch (_) {}
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

  Future<void> processPayment({bool isArabic = true}) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;

    final double promoDiscount = currentState.promoDiscount;
    final String? appliedPromo = currentState.appliedPromo;

    emit(CheckoutProcessing());

    try {
      final String branchName = currentState.selectedBranch?.nameAr ?? '';
      final String? branchId = currentState.selectedBranch?.id;

      await Future.delayed(const Duration(seconds: 2));
      await _cartCubit.checkout(
        branchId: branchId,
        branchName: branchName,
        promoDiscount: promoDiscount,
        appliedPromo: appliedPromo,
        isArabic: isArabic,
      );

      emit(CheckoutSuccess());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(CheckoutError(message));
      if (state is! CheckoutInitial) {
        emit(CheckoutInitial(
          selectedMethod: 'Cashier',
          branches: appBranches,
          selectedBranch: currentState.selectedBranch,
          appliedPromo: currentState.appliedPromo,
          promoDiscount: currentState.promoDiscount,
        ));
      }
    }
  }
}
