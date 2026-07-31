import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final String status;
  final String branchName;
  final String fulfillmentType;
  final String? deliveryAddress;
  final String? customerNote;
  final String? customerPhone;
  final String paymentMethod;
  final String? promoCode;
  final double discountAmount;
  final List<String> hiddenForUsers;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.branchName = '',
    this.fulfillmentType = 'pickup',
    this.deliveryAddress,
    this.customerNote,
    this.customerPhone,
    this.paymentMethod = 'cash',
    this.promoCode,
    this.discountAmount = 0.0,
    this.hiddenForUsers = const [],
    required this.createdAt,
  });

  OrderEntity copyWith({
    String? id,
    String? userId,
    List<OrderItemEntity>? items,
    double? totalAmount,
    String? status,
    String? branchName,
    String? fulfillmentType,
    Object? deliveryAddress = _sentinel,
    Object? customerNote = _sentinel,
    Object? customerPhone = _sentinel,
    String? paymentMethod,
    Object? promoCode = _sentinel,
    double? discountAmount,
    List<String>? hiddenForUsers,
    DateTime? createdAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      branchName: branchName ?? this.branchName,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      deliveryAddress: deliveryAddress == _sentinel
          ? this.deliveryAddress
          : deliveryAddress as String?,
      customerNote: customerNote == _sentinel
          ? this.customerNote
          : customerNote as String?,
      customerPhone: customerPhone == _sentinel
          ? this.customerPhone
          : customerPhone as String?,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode == _sentinel ? this.promoCode : promoCode as String?,
      discountAmount: discountAmount ?? this.discountAmount,
      hiddenForUsers: hiddenForUsers ?? this.hiddenForUsers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        totalAmount,
        status,
        branchName,
        fulfillmentType,
        deliveryAddress,
        customerNote,
        customerPhone,
        paymentMethod,
        promoCode,
        discountAmount,
        hiddenForUsers,
        createdAt,
      ];
}

const Object _sentinel = Object();
