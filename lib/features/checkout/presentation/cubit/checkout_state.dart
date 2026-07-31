import 'package:equatable/equatable.dart';
import '../../../../core/models/branch.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final String selectedMethod;
  final String fulfillmentType;
  final Branch? selectedBranch;
  final List<Branch> branches;
  final List<String> savedAddresses;
  final String? selectedAddress;
  final String driveThruNote;

  // ── Promo Code ────────────────────────────────────────────────────────────
  /// The validated promo code string (null = none applied)
  final String? appliedPromo;

  /// Absolute EGP discount amount (0.0 = no discount)
  final double promoDiscount;

  /// Arabic error message to display when validation fails
  final String? promoError;

  const CheckoutInitial({
    this.selectedMethod = 'Cashier',
    this.fulfillmentType = 'pickup',
    this.selectedBranch,
    this.branches = const [],
    this.savedAddresses = const [],
    this.selectedAddress,
    this.driveThruNote = '',
    this.appliedPromo,
    this.promoDiscount = 0.0,
    this.promoError,
  });

  CheckoutInitial copyWith({
    String? selectedMethod,
    String? fulfillmentType,
    Object? selectedBranch = _sentinel,
    List<Branch>? branches,
    List<String>? savedAddresses,
    Object? selectedAddress = _sentinel,
    String? driveThruNote,
    Object? appliedPromo = _sentinel,
    double? promoDiscount,
    Object? promoError = _sentinel,
  }) {
    return CheckoutInitial(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      selectedBranch: selectedBranch == _sentinel
          ? this.selectedBranch
          : selectedBranch as Branch?,
      branches: branches ?? this.branches,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      selectedAddress: selectedAddress == _sentinel
          ? this.selectedAddress
          : selectedAddress as String?,
      driveThruNote: driveThruNote ?? this.driveThruNote,
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
        fulfillmentType,
        selectedBranch,
        branches,
        savedAddresses,
        selectedAddress,
        driveThruNote,
        appliedPromo,
        promoDiscount,
        promoError,
      ];
}

/// Emitted while the promo code API call is in flight.
/// The UI shows a spinner; all other page interactions are preserved.
class CheckoutValidatingPromo extends CheckoutState {
  final CheckoutInitial data;

  const CheckoutValidatingPromo(this.data);

  @override
  List<Object?> get props => [data];
}

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
