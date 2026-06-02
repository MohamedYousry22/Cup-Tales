import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;

  const OrdersLoaded(this.orders);

  static bool _isHistoryStatus(String status) {
    final s = status.toLowerCase().trim();
    return s == 'completed' ||
        s == 'delivered' ||
        s == 'cancelled' ||
        s == 'canceled';
  }

  List<OrderEntity> get activeOrders =>
      orders.where((o) => !_isHistoryStatus(o.status)).toList();

  List<OrderEntity> get historyOrders =>
      orders.where((o) => _isHistoryStatus(o.status)).toList();

  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
