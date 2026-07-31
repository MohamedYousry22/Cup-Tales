import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/services/branch_service.dart';
import '../../../../core/services/promo_code_service.dart';
import '../../../../core/models/branch.dart';
import '../../../../core/local_storage/prefs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit _cartCubit;
  final BranchService _branchService;
  final PromoCodeService _promoCodeService;
  final PrefsService _prefsService;

  CheckoutCubit(
    this._cartCubit,
    this._branchService,
    this._promoCodeService,
    this._prefsService,
  ) : super(_createInitialState(_prefsService)) {
    loadBranches();
    loadSavedAddresses();
  }

  @override
  void emit(CheckoutState state) {
    if (!isClosed) super.emit(state);
  }

  static CheckoutInitial _createInitialState(PrefsService prefsService) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final savedAddresses = prefsService.getSavedAddresses(userId);
    final lastAddress = prefsService.getSelectedAddress(userId);
    return CheckoutInitial(
      branches: appBranches,
      selectedBranch: _getInitialBranch(appBranches, prefsService),
      savedAddresses: savedAddresses,
      selectedAddress: savedAddresses.contains(lastAddress)
          ? lastAddress
          : (savedAddresses.isNotEmpty ? savedAddresses.first : null),
    );
  }

  static Branch? _getInitialBranch(
    List<Branch> branches,
    PrefsService prefsService,
  ) {
    if (branches.isEmpty) return null;
    final savedId = prefsService.selectedBranchId;
    if (savedId != null) {
      return branches.firstWhere(
        (branch) => branch.id == savedId,
        orElse: () => branches.first,
      );
    }
    return branches.first;
  }

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  Future<void> loadSavedAddresses() async {
    if (_userId == 'guest') return;
    try {
      final rows = await Supabase.instance.client
          .from('user_addresses')
          .select('address')
          .eq('user_id', _userId)
          .order('created_at');
      final addresses = (rows as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['address']?.toString())
          .whereType<String>()
          .where((address) => address.trim().isNotEmpty)
          .toList(growable: false);
      if (state is CheckoutInitial) {
        final currentState = state as CheckoutInitial;
        final selected = addresses.contains(currentState.selectedAddress)
            ? currentState.selectedAddress
            : (addresses.isEmpty ? null : addresses.first);
        await _prefsService.replaceSavedAddresses(_userId, addresses);
        if (selected != null) {
          await _prefsService.setSelectedAddress(_userId, selected);
        }
        emit(currentState.copyWith(
          savedAddresses: addresses,
          selectedAddress: selected,
        ));
      }
    } catch (_) {
      // Keep the local cache when the device is offline.
    }
  }

  // ── Branch loading ──────────────────────────────────────────────────────────

  void loadBranches() async {
    final branches = await _branchService.getBranches();
    if (state is CheckoutInitial) {
      final s = state as CheckoutInitial;
      emit(s.copyWith(
        branches: branches,
        selectedBranch:
            branches.any((branch) => branch.id == s.selectedBranch?.id)
                ? s.selectedBranch
                : (branches.isNotEmpty ? branches.first : null),
      ));
    }
  }

  // ── Selections ──────────────────────────────────────────────────────────────

  void selectPaymentMethod(String method) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedMethod: 'Cashier'));
    }
  }

  void selectFulfillmentType(String type) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(fulfillmentType: type));
    }
  }

  void selectBranch(Branch branch) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedBranch: branch));
      _prefsService.setSelectedBranchId(branch.id);
    }
  }

  void updateDriveThruNote(String note) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(driveThruNote: note));
    }
  }

  void selectAddress(String address) {
    if (state is CheckoutInitial) {
      emit((state as CheckoutInitial).copyWith(selectedAddress: address));
      _prefsService.setSelectedAddress(_userId, address);
    }
  }

  Future<bool> saveAddress(String address) async {
    if (state is! CheckoutInitial || address.trim().isEmpty) return false;
    final currentState = state as CheckoutInitial;
    final normalized = address.trim();
    if (_userId != 'guest') {
      try {
        await Supabase.instance.client.from('user_addresses').insert({
          'user_id': _userId,
          'address': normalized,
        });
      } on PostgrestException catch (error) {
        if (error.code != '23505') return false;
      } catch (_) {
        return false;
      }
    }
    final addresses = await _prefsService.saveAddress(_userId, normalized);
    emit(currentState.copyWith(
      savedAddresses: addresses,
      selectedAddress: normalized,
    ));
    return true;
  }

  Future<bool> removeSavedAddress(String address) async {
    if (state is! CheckoutInitial) return false;
    final currentState = state as CheckoutInitial;
    if (_userId != 'guest') {
      try {
        await Supabase.instance.client
            .from('user_addresses')
            .delete()
            .eq('user_id', _userId)
            .eq('address', address);
      } catch (_) {
        return false;
      }
    }
    final addresses = currentState.savedAddresses
        .where((item) => item != address)
        .toList(growable: false);
    final selectedAddress = currentState.selectedAddress == address
        ? (addresses.isEmpty ? null : addresses.first)
        : currentState.selectedAddress;
    emit(currentState.copyWith(
      savedAddresses: addresses,
      selectedAddress: selectedAddress,
    ));
    await _prefsService.replaceSavedAddresses(_userId, addresses);
    if (selectedAddress != null) {
      await _prefsService.setSelectedAddress(_userId, selectedAddress);
    } else {
      await _prefsService.clearSelectedAddress(_userId);
    }
    return true;
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
    emit(CheckoutValidatingPromo(currentState));

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

    final branchRequired = currentState.fulfillmentType == 'pickup' ||
        currentState.fulfillmentType == 'drive_thru';
    if (branchRequired && currentState.selectedBranch == null) {
      emit(CheckoutError(isArabic
          ? 'يرجى اختيار الفرع أولاً'
          : 'Please select a branch first'));
      emit(currentState);
      return;
    }
    if (currentState.fulfillmentType == 'drive_thru' &&
        currentState.driveThruNote.trim().isEmpty) {
      emit(CheckoutError(isArabic
          ? 'يرجى كتابة نوع ولون السيارة'
          : 'Please enter the vehicle type and color'));
      emit(currentState);
      return;
    }
    if (currentState.fulfillmentType == 'delivery' &&
        (currentState.selectedAddress == null ||
            currentState.selectedAddress!.trim().isEmpty)) {
      emit(CheckoutError(isArabic
          ? 'يرجى إضافة واختيار عنوان التوصيل'
          : 'Please add and select a delivery address'));
      emit(currentState);
      return;
    }

    emit(CheckoutProcessing());

    try {
      final String branchName =
          branchRequired ? currentState.selectedBranch?.nameAr ?? '' : '';
      final String? branchId =
          branchRequired ? currentState.selectedBranch?.id : null;

      await Future.delayed(const Duration(seconds: 2));
      await _cartCubit.checkout(
        branchId: branchId,
        branchName: branchName,
        fulfillmentType: currentState.fulfillmentType,
        deliveryAddress: currentState.fulfillmentType == 'delivery'
            ? currentState.selectedAddress
            : null,
        customerNote: currentState.fulfillmentType == 'drive_thru'
            ? currentState.driveThruNote.trim()
            : null,
        paymentMethod: 'cash',
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
          fulfillmentType: currentState.fulfillmentType,
          branches: appBranches,
          selectedBranch: currentState.selectedBranch,
          savedAddresses: currentState.savedAddresses,
          selectedAddress: currentState.selectedAddress,
          driveThruNote: currentState.driveThruNote,
          appliedPromo: currentState.appliedPromo,
          promoDiscount: currentState.promoDiscount,
        ));
      }
    }
  }
}
