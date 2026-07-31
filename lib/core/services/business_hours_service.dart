class BusinessHoursService {
  static const int openingMinute = 7 * 60 + 30;
  static const int closingMinute = 30;

  const BusinessHoursService._();

  /// Cup Tales is open daily from 07:30 through 00:30:59.
  static bool isOpen([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final minuteOfDay = now.hour * 60 + now.minute;
    return minuteOfDay >= openingMinute || minuteOfDay <= closingMinute;
  }
}
