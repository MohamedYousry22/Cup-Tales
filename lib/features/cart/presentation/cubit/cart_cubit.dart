import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/supabase_cart_item.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final HiveService _hive = di.sl<HiveService>();

  CartCubit() : super(CartLoading()) {
    // Wait for Hive to be ready before loading cache
    di.appReady.then((_) => _loadFromCache());
  }

  void _loadFromCache() {
    if (!_hive.cartBox.isOpen) return;

    final cached = _hive.cartBox.get('items');
    if (cached != null && cached is List) {
      // We don't have the user yet, but we can show the UI
      final items = cached
          .map((e) => SupabaseCartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      emit(CartLoaded(items: items));
    }
  }

  void _saveToCache(List<SupabaseCartItem> items) {
    final data = items
        .map((e) => {
              'id': e.id,
              'user_id': e.userId,
              'product_id': e.productId,
              'product_name': e.productName,
              'price': e.price,
              'image': e.image,
              'quantity': e.quantity,
            })
        .toList();
    _hive.cartBox.put('items', data);
  }

  SupabaseClient get _client => Supabase.instance.client;

  void _emitLoaded({required List<SupabaseCartItem> items}) {
    emit(CartLoaded(items: items));
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
          .select('*, products(name, price, price_m, image, image_url)')
          .eq('user_id', user.id);

      final items = (data as List<dynamic>)
          .map((e) => SupabaseCartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      _emitLoaded(items: items);
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  // ── Add item to Supabase cart ───────────────────────────────────────────

  Future<void> addToCart({
    required String productId,
    required String productName,
    required double price,
    required String image,
    required int quantity,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _client
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        final newQty = (existing['quantity'] as int) + quantity;
        await _client
            .from('cart')
            .update({'quantity': newQty}).eq('id', existing['id']);
      } else {
        await _client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': quantity,
          'price': price,
        });
      }

      await loadCart();
    } catch (e) {
      emit(CartError('Failed to add to cart: ${e.toString()}'));
    }
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

  Future<void> checkout({
    String? branchName,
    double promoDiscount = 0.0,
    String? appliedPromo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || state is! CartLoaded) return;

    final cartState = state as CartLoaded;
    final items = cartState.items;
    if (items.isEmpty) return;

    emit(CartCheckingOut());
    try {
      final double totalAmount = cartState.subtotal - promoDiscount;
      
      final orderData = {
        'user_id': user.id,
        'status': 'preparing',
        'total_amount': totalAmount,
        'branch_name': branchName,
        'promo_code': appliedPromo,
        'discount_amount': promoDiscount,
        'items': items.map((e) => {
          'product_id': e.productId,
          'product_name': e.productName,
          'product_name_ar': e.productNameAr,
          'product_image': e.image,
          'total_amount': e.price,
          'quantity': e.quantity,
        }).toList(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('orders').insert(orderData);

      await _client.from('cart').delete().eq('user_id', user.id);
      _hive.cartBox.delete('items'); 
      emit(CartCheckedOut());
    } catch (e) {
      emit(CartError('Checkout failed: ${e.toString()}'));
    }
  }

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
}
