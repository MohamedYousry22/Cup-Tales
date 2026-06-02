import 'package:equatable/equatable.dart';
import '../../domain/entities/supabase_cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<SupabaseCartItem> items;
  final double discount;
  final String? appliedPromoCode;

  const CartLoaded({
    this.items = const [],
    this.discount = 0.0,
    this.appliedPromoCode,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal - discount;

  @override
  List<Object?> get props => [items, discount, appliedPromoCode];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartCheckingOut extends CartState {}

class CartCheckedOut extends CartState {}
