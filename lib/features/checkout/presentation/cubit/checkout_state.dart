import 'package:equatable/equatable.dart';
import '../../../../core/models/branch.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final String selectedMethod;
  final Branch? selectedBranch;
  final List<Branch> branches;

  // ── Promo Code ────────────────────────────────────────────────────────────
  /// The validated promo code string (null = none applied)
  final String? appliedPromo;

  /// Absolute EGP discount amount (0.0 = no discount)
  final double promoDiscount;

  /// Arabic error message to display when validation fails
  final String? promoError;

  const CheckoutInitial({
    this.selectedMethod = 'Cashier',
    this.selectedBranch,
    this.branches = const [],
    this.appliedPromo,
    this.promoDiscount = 0.0,
    this.promoError,
  });

  CheckoutInitial copyWith({
    String? selectedMethod,
    Branch? selectedBranch,
    List<Branch>? branches,
    Object? appliedPromo = _sentinel,
    double? promoDiscount,
    Object? promoError = _sentinel,
  }) {
    return CheckoutInitial(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      branches: branches ?? this.branches,
      appliedPromo: appliedPromo == _sentinel
          ? this.appliedPromo
          : appliedPromo as String?,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      promoError:
          promoError == _sentinel ? this.promoError : promoError as String?,
    );
  }

  @override
  List<Object?> get props => [
        selectedMethod,
        selectedBranch,
        branches,
        appliedPromo,
        promoDiscount,
        promoError,
      ];
}

/// Emitted while the promo code API call is in flight.
/// The UI shows a spinner; all other page interactions are preserved.
class CheckoutValidatingPromo extends CheckoutState {}

class CheckoutProcessing extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object> get props => [message];
}

// Internal sentinel for copyWith nullable fields
const Object _sentinel = Object();
