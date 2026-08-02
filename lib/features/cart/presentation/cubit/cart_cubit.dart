import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/business_hours_service.dart';
import '../../domain/entities/supabase_cart_item.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final HiveService _hive = di.sl<HiveService>();

  CartCubit() : super(CartLoading()) {
    // Wait for Hive to be ready before loading cache
    di.appReady.then((_) {
      if (!isClosed) _loadFromCache();
    });
  }

  @override
  void emit(CartState state) {
    if (!isClosed) super.emit(state);
  }

  void _loadFromCache() {
    if (!_hive.cartBox.isOpen) return;

    try {
      final cached = _hive.cartBox.get('items');
      if (cached != null && cached is List) {
        final items = cached
            .map((e) =>
                SupabaseCartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        emit(CartLoaded(items: items));
      }
    } catch (_) {
      // Stale / incompatible cache — clear it so the app never crashes
      // on startup. The next loadCart() will fetch fresh data.
      _hive.cartBox.delete('items');
      emit(const CartLoaded(items: []));
    }
  }

  void _saveToCache(List<SupabaseCartItem> items) {
    final data = items.map((e) => e.toJson()).toList();
    _hive.cartBox.put('items', data);
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Helper to emit Loaded state with preserved discount ────────────────

  void _emitLoaded({
    required List<SupabaseCartItem> items,
    double? discount,
    String? promoCode,
  }) {
    final currentDiscount = discount ??
        (state is CartLoaded ? (state as CartLoaded).discount : 0.0);
    final currentPromo = promoCode ??
        (state is CartLoaded ? (state as CartLoaded).appliedPromoCode : null);

    emit(CartLoaded(
      items: items,
      discount: currentDiscount,
      appliedPromoCode: currentPromo,
    ));

    _saveToCache(items);
  }

  // ── Load cart from Supabase ─────────────────────────────────────────────

  Future<void> loadCart() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      emit(const CartError('No user logged in.'));
      return;
    }

    emit(CartLoading());
    try {
      final data = await _client
          .from('cart')
          .select(
              '*, products(name, name_en, name_ar, price, price_m, image, image_url)')
          .eq('user_id', user.id);

      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      _emitLoaded(items: items);
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  // ── Add item to cart — smart merge by (product_id + size + options + addons)
  //
  // Merge rules:
  //   • Identical product_id + size + options map + addons list → increment qty
  //   • Any difference in the above                             → new row

  Future<void> addToCart({
    required String productId,
    required String productName,
    required double basePrice,
    required double price, // basePrice + addons total
    required String image,
    required int quantity,
    String? selectedSize,
    Map<String, String> selectedOptions = const {},
    List<Map<String, dynamic>> selectedAddons = const [],
    String? selectedOption,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch all existing rows for this product+size combination
      var query = _client
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      if (selectedSize != null) {
        query = query.eq('selected_size', selectedSize);
      } else {
        query = query.isFilter('selected_size', null);
      }

      final List<dynamic> potentialMatches = await query;
      Map<String, dynamic>? exactMatch;

      // 2. Find exact match by comparing options map AND addons list
      for (final row in potentialMatches) {
        // ── Compare options (Map<String,String>) ────────────────────────────
        final rawOptions = row['selected_options'];
        Map<String, String> dbOptions = const {};
        if (rawOptions is Map) {
          dbOptions = rawOptions.map(
              (k, v) => MapEntry(k.toString().trim(), v.toString().trim()));
        }
        final bool optionsMatch = _mapsEqual(dbOptions, selectedOptions);

        // ── Compare add-ons (List<Map>) by name ─────────────────────────────
        final rawAddons = row['selected_addons'];
        List<Map<String, dynamic>> dbAddons = const [];
        if (rawAddons is List) {
          dbAddons = rawAddons
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        final bool addonsMatch = _addonListsEqual(dbAddons, selectedAddons);

        // ── Compare legacy single option field ──────────────────────────────
        final dbSelectedOption = row['selected_option'] as String?;
        final bool singleOptionMatch = dbSelectedOption == selectedOption;

        if (optionsMatch && addonsMatch && singleOptionMatch) {
          exactMatch = row;
          break;
        }
      }

      if (exactMatch != null) {
        // ── Merge: increment the qty of the existing exact-match row ────────
        final newQty = (exactMatch['quantity'] as int) + quantity;
        await _client
            .from('cart')
            .update({'quantity': newQty}).eq('id', exactMatch['id']);
      } else {
        // ── Insert: brand-new configuration ────────────────────────────────
        await _client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': quantity,
          'base_price': basePrice,
          'price': price,
          if (selectedSize != null) 'selected_size': selectedSize,
          if (selectedOptions.isNotEmpty) 'selected_options': selectedOptions,
          if (selectedAddons.isNotEmpty) 'selected_addons': selectedAddons,
          if (selectedOption != null) 'selected_option': selectedOption,
        });
      }

      await loadCart();
    } catch (e) {
      emit(CartError('Failed to add to cart: ${e.toString()}'));
    }
  }

  // ── Helpers for duplicate matching ──────────────────────────────────────

  /// Deep-equal comparison for two String→String maps.
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  /// Compares two addon lists by the 'name' field (order-insensitive).
  bool _addonListsEqual(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    final aSorted = List<Map<String, dynamic>>.from(a)
      ..sort((x, y) =>
          (x['name']?.toString() ?? '').compareTo(y['name']?.toString() ?? ''));
    final bSorted = List<Map<String, dynamic>>.from(b)
      ..sort((x, y) =>
          (x['name']?.toString() ?? '').compareTo(y['name']?.toString() ?? ''));
    for (int i = 0; i < aSorted.length; i++) {
      if (aSorted[i]['name']?.toString() != bSorted[i]['name']?.toString()) {
        return false;
      }
    }
    return true;
  }

  // ── Quantity & Removal ──────────────────────────────────────────────────

  Future<void> increaseQuantity(SupabaseCartItem item) async {
    try {
      await _client
          .from('cart')
          .update({'quantity': item.quantity + 1}).eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to update quantity.'));
    }
  }

  Future<void> decreaseQuantity(SupabaseCartItem item) async {
    if (item.quantity <= 1) return;
    try {
      await _client
          .from('cart')
          .update({'quantity': item.quantity - 1}).eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to update quantity.'));
    }
  }

  Future<void> removeItem(SupabaseCartItem item) async {
    try {
      await _client.from('cart').delete().eq('id', item.id);
      await _refreshAfterChange();
    } catch (e) {
      emit(CartError('Failed to remove item.'));
    }
  }

  Future<void> _refreshAfterChange() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final data = await _client
        .from('cart')
        .select(
            '*, products(name, name_en, name_ar, price, price_m, image, image_url)')
        .eq('user_id', user.id);
    final items = (data as List<dynamic>)
        .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (state is CartLoaded) {
      final s = state as CartLoaded;
      if (s.appliedPromoCode != null) {
        await applyPromoCode(s.appliedPromoCode!);
      } else {
        _emitLoaded(items: items);
      }
    } else {
      _emitLoaded(items: items);
    }
  }

  // ── Promo Code ──────────────────────────────────────────────────────────

  Future<void> applyPromoCode(String code) async {
    final user = _client.auth.currentUser;
    if (user == null || state is! CartLoaded) return;

    try {
      final data = await _client
          .from('cart')
          .select('*, products(name, price, price_m, image, image_url)')
          .eq('user_id', user.id);
      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      _emitLoaded(items: items);
    } catch (e) {
      emit(CartError('Failed to refresh cart: ${e.toString()}'));
    }
  }

  // ── Checkout ────────────────────────────────────────────────────────────
  //
  // Each cart item is mapped to the strict canonical OrderItem schema before
  // being sent to Supabase, guaranteeing all historical and future data is
  // consistent. The 'status' field is intentionally omitted; cash orders use
  // the DB default status.

  Future<void> checkout({
    String? branchId,
    String? branchName,
    String fulfillmentType = 'pickup',
    String? deliveryAddress,
    String? customerNote,
    String paymentMethod = 'cash',
    double promoDiscount = 0.0,
    String? appliedPromo,
    bool isArabic = true,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || state is! CartLoaded) return;

    final cartState = state as CartLoaded;
    final items = cartState.items;
    if (items.isEmpty) return;
    if (!BusinessHoursService.canPlaceOrder(userId: user.id)) {
      throw Exception(isArabic
          ? 'نستقبل الطلبات يوميًا من 7:30 صباحًا حتى 12:30 بعد منتصف الليل.'
          : 'Orders are available daily from 7:30 AM to 12:30 AM.');
    }

    emit(CartCheckingOut());
    try {
      final unavailableItems =
          await _findUnavailableItemsForBranch(items, branchId);
      if (unavailableItems.isNotEmpty) {
        throw Exception(_branchAvailabilityMessage(
          unavailableItems,
          isArabic: isArabic,
        ));
      }

      final double totalAmount =
          (cartState.subtotal - cartState.discount - promoDiscount)
              .clamp(0.0, double.infinity);

      // ── Map every cart item to the strict canonical OrderItem schema ──────
      // This is the single source of truth for what gets written to orders.items.
      final List<Map<String, dynamic>> normalizedItems = items.map((e) {
        final double unitPrice = e.price;
        final int qty = e.quantity;
        return <String, dynamic>{
          // ── Identity ────────────────────────────────────────────────────
          'product_id': e.productId,
          // ── Names ──────────────────────────────────────────────────────
          'product_name_en': e.productName,
          'product_name_ar': e.productNameAr,
          // ── Pricing ────────────────────────────────────────────────────
          'base_price': double.parse(e.basePrice.toStringAsFixed(2)),
          'unit_price': double.parse(unitPrice.toStringAsFixed(2)),
          'quantity': qty,
          'total_price': double.parse((unitPrice * qty).toStringAsFixed(2)),
          // ── Media ──────────────────────────────────────────────────────
          'image_url': e.image.isNotEmpty ? e.image : null,
          // ── Variants / Options ─────────────────────────────────────────
          'selected_size': e.selectedSize,
          'selected_options': e.selectedOptions, // Map<String,String>
          'selected_addons': e.selectedAddons, // List<Map<String,dynamic>>
          'selected_option': e.selectedOption,
        };
      }).toList();

      final orderData = <String, dynamic>{
        'user_id': user.id,
        // No 'status' field; DB default is applied automatically.
        'total_amount': double.parse(totalAmount.toStringAsFixed(2)),
        'branch_id': branchId,
        'branch_name': branchName,
        'fulfillment_type': fulfillmentType,
        'delivery_address': deliveryAddress,
        'customer_note': customerNote,
        'payment_method': paymentMethod,
        'promo_code': appliedPromo,
        'discount_amount': double.parse(promoDiscount.toStringAsFixed(2)),
        'items': normalizedItems,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('orders').insert(orderData);

      await _client.from('cart').delete().eq('user_id', user.id);
      _hive.cartBox.delete('items');
      emit(CartCheckedOut());
    } catch (e) {
      _emitLoaded(
        items: items,
        discount: cartState.discount,
        promoCode: cartState.appliedPromoCode,
      );
      if (e.toString().contains('CUP_TALES_CLOSED')) {
        throw Exception(isArabic
            ? 'نستقبل الطلبات يوميًا من 7:30 صباحًا حتى 12:30 بعد منتصف الليل.'
            : 'Orders are available daily from 7:30 AM to 12:30 AM.');
      }
      if (e.toString().contains('CUP_TALES_PHONE_REQUIRED')) {
        throw Exception(isArabic
            ? 'يرجى إضافة رقم موبايل مصري صحيح إلى بياناتك قبل تأكيد الطلب.'
            : 'Add a valid Egyptian mobile number before confirming the order.');
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<SupabaseCartItem>> _findUnavailableItemsForBranch(
    List<SupabaseCartItem> items,
    String? branchId,
  ) async {
    final productIds = items.map((item) => item.productId).toSet().toList();
    if (productIds.isEmpty) return const [];

    final productRows = await _client
        .from('products')
        .select('id')
        .eq('is_active', true)
        .inFilter('id', productIds);

    final globallyActiveIds = <String>{};
    for (final row in productRows as List<dynamic>) {
      final product = row as Map<String, dynamic>;
      globallyActiveIds.add(product['id'].toString());
    }

    if (branchId == null || branchId.trim().isEmpty) {
      return items
          .where((item) => !globallyActiveIds.contains(item.productId))
          .toList();
    }

    final branchStatusRows = await _client
        .from('branch_product_status')
        .select('product_id, is_active')
        .eq('branch_id', branchId)
        .inFilter('product_id', productIds);

    final branchInactiveIds = <String>{};
    for (final row in branchStatusRows as List<dynamic>) {
      final status = row as Map<String, dynamic>;
      final isActive = status['is_active'] as bool? ?? true;
      if (!isActive) {
        branchInactiveIds.add(status['product_id'].toString());
      }
    }

    return items
        .where((item) =>
            !globallyActiveIds.contains(item.productId) ||
            branchInactiveIds.contains(item.productId))
        .toList();
  }

  String _branchAvailabilityMessage(
    List<SupabaseCartItem> unavailableItems, {
    required bool isArabic,
  }) {
    if (unavailableItems.length == 1) {
      final productName = isArabic
          ? unavailableItems.first.productNameAr ??
              unavailableItems.first.productName
          : unavailableItems.first.productName;
      return isArabic
          ? 'عذرًا، "$productName" غير متوفر حاليًا في الفرع المختار. جرّب اختيار فرع آخر أو أعد المحاولة لاحقًا.'
          : 'Sorry, "$productName" is currently unavailable at the selected branch. Please choose another branch or try again later.';
    }

    final names = unavailableItems
        .take(3)
        .map((item) => isArabic
            ? item.productNameAr ?? item.productName
            : item.productName)
        .join(isArabic ? '، ' : ', ');
    return isArabic
        ? 'عذرًا، بعض المنتجات غير متوفرة حاليًا في الفرع المختار: $names. يمكنك اختيار فرع آخر أو أعد المحاولة لاحقًا.'
        : 'Sorry, some items are currently unavailable at the selected branch: $names. Please choose another branch or try again later.';
  }

  // ── Clear cart ─────────────────────────────────────────────────────────
  Future<void> clearCart() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('cart').delete().eq('user_id', user.id);
      _hive.cartBox.delete('items');
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError('Failed to clear cart: ${e.toString()}'));
    }
  }

  // ── Batch Replace (Reorder Logic) ──────────────────────────────────────

  Future<bool> replaceCartWithItems(List<dynamic> newItems) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    // We do not emit CartLoading here because we want to update seamlessly in the background
    // if the user has already navigated away (e.g., fast reorder).

    try {
      // 1. Clear database cart
      await _client.from('cart').delete().eq('user_id', user.id);

      // 2. Prepare items for bulk insert
      final List<Map<String, dynamic>> insertData = [];
      for (final dynamic item in newItems) {
        insertData.add({
          'user_id': user.id,
          'product_id': item.productId,
          'quantity': item.quantity,
          'base_price': item.basePrice,
          'price': item.unitPrice,
          if (item.selectedSize != null) 'selected_size': item.selectedSize,
          if ((item.selectedOptions as Map).isNotEmpty)
            'selected_options': item.selectedOptions,
          if ((item.selectedAddons as List).isNotEmpty)
            'selected_addons': item.selectedAddons,
          if (item.selectedOption != null)
            'selected_option': item.selectedOption,
        });
      }

      // 3. Bulk insert to Supabase
      if (insertData.isNotEmpty) {
        await _client.from('cart').insert(insertData);
      }

      // 4. Reload from database silently to refresh joined tables without flicker
      final data = await _client
          .from('cart')
          .select(
              '*, products(name, name_en, name_ar, price, price_m, image, image_url)')
          .eq('user_id', user.id);

      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Emit new state exactly ONCE
      _emitLoaded(items: items, discount: 0.0, promoCode: null);
      return true;
    } catch (e) {
      emit(CartError('Failed to reorder: ${e.toString()}'));
      return false;
    }
  }
}
