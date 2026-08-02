class BusinessHoursService {
  static const int openingMinute = 7 * 60 + 30;
  static const int closingMinute = 30;
  static const String appReviewUserId = 'a3ffad5e-025a-465f-811b-b15a9f84809a';
  static const bool _bypassForDeviceTesting = bool.fromEnvironment(
    'CUP_TALES_BYPASS_BUSINESS_HOURS',
  );

  const BusinessHoursService._();

  /// Cup Tales is open daily from 07:30 through 00:30:59.
  static bool isOpen([DateTime? dateTime]) {
    if (_bypassForDeviceTesting) return true;
    final now = dateTime ?? DateTime.now();
    final minuteOfDay = now.hour * 60 + now.minute;
    return minuteOfDay >= openingMinute || minuteOfDay <= closingMinute;
  }

  static bool canPlaceOrder({
    required String userId,
    DateTime? dateTime,
  }) {
    return userId == appReviewUserId || isOpen(dateTime);
  }
}
