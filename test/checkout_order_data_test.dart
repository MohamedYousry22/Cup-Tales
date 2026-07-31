import 'package:cup_tales/core/models/branch.dart';
import 'package:cup_tales/features/orders/data/models/order_model.dart';
import 'package:cup_tales/core/utils/phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the two supported Mahalla branches are exposed', () {
    expect(appBranches.map((branch) => branch.id), ['mahalla1', 'mahalla2']);
    expect(
      appBranches.every(
        (branch) => supportedBranchIds.contains(branch.id),
      ),
      isTrue,
    );
  });

  test('order model parses delivery details and keeps legacy defaults', () {
    final baseJson = <String, dynamic>{
      'id': 'order-1',
      'user_id': 'user-1',
      'items': <dynamic>[],
      'total_amount': 125,
      'status': 'pending',
      'created_at': '2026-07-31T12:00:00.000Z',
    };

    final delivery = OrderModel.fromJson({
      ...baseJson,
      'fulfillment_type': 'delivery',
      'delivery_address': 'Mahalla, Street 1',
      'payment_method': 'cash',
      'customer_phone': '01012345678',
    });
    expect(delivery.fulfillmentType, 'delivery');
    expect(delivery.deliveryAddress, 'Mahalla, Street 1');
    expect(delivery.paymentMethod, 'cash');
    expect(delivery.customerPhone, '01012345678');

    final legacy = OrderModel.fromJson(baseJson);
    expect(legacy.fulfillmentType, 'pickup');
    expect(legacy.deliveryAddress, isNull);
    expect(legacy.paymentMethod, 'cash');
    expect(legacy.customerPhone, isNull);
  });

  test('Egyptian mobile phone validation accepts only supported prefixes', () {
    expect(EgyptianPhoneValidator.isValid('01012345678'), isTrue);
    expect(EgyptianPhoneValidator.isValid('01112345678'), isTrue);
    expect(EgyptianPhoneValidator.isValid('01212345678'), isTrue);
    expect(EgyptianPhoneValidator.isValid('01512345678'), isTrue);
    expect(EgyptianPhoneValidator.isValid('01312345678'), isFalse);
    expect(EgyptianPhoneValidator.isValid('1012345678'), isFalse);
    expect(EgyptianPhoneValidator.isValid('010123456789'), isFalse);
  });
}
