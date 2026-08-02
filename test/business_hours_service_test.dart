import 'package:cup_tales/core/services/business_hours_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens at 07:30 and remains open through 00:30', () {
    expect(
      BusinessHoursService.isOpen(DateTime(2026, 7, 31, 7, 30)),
      isTrue,
    );
    expect(
      BusinessHoursService.isOpen(DateTime(2026, 7, 31, 23, 59)),
      isTrue,
    );
    expect(
      BusinessHoursService.isOpen(DateTime(2026, 8, 1, 0, 30, 59)),
      isTrue,
    );
  });

  test('closes at 00:31 and remains closed through 07:29', () {
    expect(
      BusinessHoursService.isOpen(DateTime(2026, 8, 1, 0, 31)),
      isFalse,
    );
    expect(
      BusinessHoursService.isOpen(DateTime(2026, 8, 1, 7, 29, 59)),
      isFalse,
    );
  });

  test('App Review account can place orders outside normal hours', () {
    expect(
      BusinessHoursService.canPlaceOrder(
        userId: BusinessHoursService.appReviewUserId,
        dateTime: DateTime(2026, 8, 2, 4),
      ),
      isTrue,
    );
    expect(
      BusinessHoursService.canPlaceOrder(
        userId: 'regular-user',
        dateTime: DateTime(2026, 8, 2, 4),
      ),
      isFalse,
    );
  });
}
