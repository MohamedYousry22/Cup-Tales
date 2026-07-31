import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/usecases/get_user_orders_usecase.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'orders_state.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import 'package:flutter/foundation.dart';

class OrdersCubit extends Cubit<OrdersState> {
  late final GetUserOrdersUseCase _getUserOrders;
  final HiveService _hive = di.sl<HiveService>();
  RealtimeChannel? _channel;

  OrdersCubit() : super(const OrdersInitial()) {
    // Wait for Hive AND Supabase to be ready before initializing usecase or loading
    di.appReady.then((_) {
      if (isClosed) return;
      _getUserOrders = GetUserOrdersUseCase(
        OrdersRepositoryImpl(Supabase.instance.client),
      );
      _loadFromCache();
      _startSubscription();
    });
  }

  @override
  void emit(OrdersState state) {
    if (!isClosed) super.emit(state);
  }

  void _startSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _subscribeToOrders(user.id);
    }
  }

  void _subscribeToOrders(String userId) {
    _channel?.unsubscribe();

    _channel =
        Supabase.instance.client.channel('orders-debug').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              callback: (payload) {
                debugPrint(
                    'DEBUG: ANY change on orders table: ${payload.eventType} - ${payload.newRecord}');
                _fetchOrdersOnly();
              },
            );

    _channel!.subscribe((status, [error]) {
      debugPrint('DEBUG: Channel status: $status error: $error');
    });
  }

  // ── Hive cache helpers ────────────────────────────────────────────────────
  // Canonical keys are used exclusively — legacy keys are never written back.

  void _loadFromCache() {
    if (!_hive.ordersBox.isOpen) return;

    final cached = _hive.ordersBox.get('list');
    if (cached != null && cached is List) {
      final orders = cached.map((e) {
        final map = Map<String, dynamic>.from(e);

        final itemsList = (map['items'] as List? ?? []).map((i) {
          final itemMap = Map<String, dynamic>.from(i);
          final int qty = (itemMap['quantity'] as num? ?? 1).toInt();
          final double unit =
              ((itemMap['unit_price'] ?? itemMap['price'] ?? 0.0) as num)
                  .toDouble();
          return OrderItemEntity(
            productId: itemMap['product_id']?.toString() ?? '',
            productNameEn: itemMap['product_name_en'] as String? ??
                itemMap['product_name'] as String? ??
                'Unknown',
            productNameAr: itemMap['product_name_ar'] as String?,
            imageUrl: itemMap['image_url'] as String? ??
                itemMap['image'] as String? ??
                itemMap['product_image'] as String?,
            unitPrice: unit,
            basePrice: ((itemMap['base_price'] ?? unit) as num).toDouble(),
            quantity: qty,
            totalPrice:
                ((itemMap['total_price'] ?? itemMap['total_amount']) as num?)
                        ?.toDouble() ??
                    double.parse((unit * qty).toStringAsFixed(2)),
            selectedSize: itemMap['selected_size'] as String?,
            selectedOptions: (itemMap['selected_options'] is Map)
                ? (itemMap['selected_options'] as Map).map((key, value) =>
                    MapEntry(key.toString().trim(), value.toString().trim()))
                : const {},
            selectedAddons: (itemMap['selected_addons'] is List)
                ? (itemMap['selected_addons'] as List)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
                : const [],
            selectedOption: itemMap['selected_option'] as String?,
          );
        }).toList();

        return OrderEntity(
          id: map['id'].toString(),
          userId: map['user_id'] as String,
          items: itemsList,
          totalAmount: (map['total_amount'] as num).toDouble(),
          status: map['status'] as String? ?? 'pending',
          branchName: map['branch_name'] as String? ?? '',
          fulfillmentType: map['fulfillment_type'] as String? ?? 'pickup',
          deliveryAddress: map['delivery_address'] as String?,
          customerNote: map['customer_note'] as String?,
          customerPhone: map['customer_phone'] as String?,
          paymentMethod: map['payment_method'] as String? ?? 'cash',
          promoCode: map['promo_code'] as String?,
          discountAmount: ((map['discount_amount'] ?? 0.0) as num).toDouble(),
          hiddenForUsers: _parseHiddenForUsers(map['hidden_for_users']),
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      emit(OrdersLoaded(_visibleOrders(orders, userId)));
    }
  }

  List<OrderEntity> _visibleOrders(List<OrderEntity> orders, String? userId) {
    if (userId == null || userId.isEmpty) return orders;
    return orders
        .where((order) => !order.hiddenForUsers.contains(userId))
        .toList();
  }

  List<String> _parseHiddenForUsers(dynamic raw) {
    if (raw is List) {
      return raw.map((id) => id.toString()).toList();
    }
    if (raw is String && raw.startsWith('{') && raw.endsWith('}')) {
      final body = raw.substring(1, raw.length - 1).trim();
      if (body.isEmpty) return const [];
      return body.split(',').map((id) => id.trim()).toList();
    }
    return const [];
  }

  void _saveToCache(List<OrderEntity> orders) {
    final data = orders
        .map((e) => {
              'id': e.id,
              'user_id': e.userId,
              'items': e.items
                  .map((i) => {
                        'product_id': i.productId,
                        'product_name_en': i.productNameEn,
                        'product_name_ar': i.productNameAr,
                        'image_url': i.imageUrl,
                        'base_price': i.basePrice,
                        'unit_price': i.unitPrice,
                        'quantity': i.quantity,
                        'total_price': i.totalPrice,
                        'selected_size': i.selectedSize,
                        'selected_options': i.selectedOptions,
                        'selected_addons': i.selectedAddons,
                        'selected_option': i.selectedOption,
                      })
                  .toList(),
              'total_amount': e.totalAmount,
              'status': e.status,
              'branch_name': e.branchName,
              'fulfillment_type': e.fulfillmentType,
              'delivery_address': e.deliveryAddress,
              'customer_note': e.customerNote,
              'customer_phone': e.customerPhone,
              'payment_method': e.paymentMethod,
              'promo_code': e.promoCode,
              'discount_amount': e.discountAmount,
              'hidden_for_users': e.hiddenForUsers,
              'created_at': e.createdAt.toIso8601String(),
            })
        .toList();
    _hive.ordersBox.put('list', data);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    await _fetchOrdersOnly();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _subscribeToOrders(user.id);
    }
  }

  Future<bool> clearOrders() async {
    await di.appReady;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const OrdersError('No user logged in.'));
      return false;
    }

    try {
      await Supabase.instance.client.rpc('hide_my_orders');
      _saveToCache(const []);
      emit(const OrdersLoaded([]));
      return true;
    } catch (e) {
      emit(OrdersError('Failed to clear orders: ${e.toString()}'));
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    await di.appReady;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const OrdersError('No user logged in.'));
      return false;
    }

    try {
      final didCancel = await Supabase.instance.client.rpc(
        'cancel_my_order',
        params: {'p_order_id': orderId},
      );

      if (didCancel != true) {
        return false;
      }

      if (state is OrdersLoaded) {
        final current = state as OrdersLoaded;
        final updatedOrders = current.orders
            .map((order) => order.id == orderId
                ? order.copyWith(status: 'cancelled')
                : order)
            .toList();
        _saveToCache(updatedOrders);
        emit(OrdersLoaded(updatedOrders));
      } else {
        await _fetchOrdersOnly();
      }

      return true;
    } catch (e) {
      emit(OrdersError('Failed to cancel order: ${e.toString()}'));
      return false;
    }
  }

  Future<void> _fetchOrdersOnly() async {
    await di.appReady;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const OrdersError('No user logged in.'));
      return;
    }

    // Don't emit loading if we already have data (prevents flicker on realtime updates)
    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }

    try {
      final orders = await _getUserOrders(user.id);
      final visibleOrders = _visibleOrders(orders, user.id);
      debugPrint(
          'DEBUG: Fetched ${orders.length} orders from Supabase (${visibleOrders.length} visible)');
      _saveToCache(visibleOrders);
      emit(OrdersLoaded(visibleOrders));
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }
}
