import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class TranslationHelper {
  /// Returns the correct localised product name strictly following the
  /// active app locale. Never mixes languages on the same screen.
  ///
  /// - Arabic locale → returns [nameAr] if non-null/non-empty,
  ///   otherwise falls back to a generic Arabic placeholder.
  /// - English locale → always returns [nameEn], ignoring [nameAr].
  static String translateProductName(
    BuildContext context,
    String nameEn,
    String? nameAr,
  ) {
    final isArabic = context.loc.isAr;

    if (isArabic) {
      // Strict Arabic: use nameAr if available, else Arabic fallback
      if (nameAr != null && nameAr.isNotEmpty) return nameAr;
      // Try the hard-coded mapping for known English names
      final mapped = _mapToArabic(nameEn);
      if (mapped != null) return mapped;
      // Last resort: generic Arabic placeholder
      return 'منتج';
    } else {
      // Strict English: always return the English name
      return nameEn.isNotEmpty ? nameEn : 'Product';
    }
  }

  /// Hard-coded Arabic overrides for well-known product names.
  static String? _mapToArabic(String nameEn) {
    final upper = nameEn.toUpperCase().trim();
    if (upper == 'ICED CAPPUCCINO') return 'آيس كابتشينو';
    if (upper == 'CARAMEL') return 'كراميل';
    if (upper == 'MINT LEMON') return 'ليمون نعناع';
    if (upper == 'MANGO') return 'مانجو فريش';
    if (upper.contains('ORANGE')) return 'برتقال فريش';
    if (upper.contains('STRAWBERRY')) return 'فراولة فريش';
    if (upper.contains('COFFEE')) return 'قهوة';
    if (upper.contains('TEA')) return 'شاي';
    return null;
  }

  /// Translates individual options (e.g. Biscuit -> بسكوت)
  static String translateOption(BuildContext context, String option) {
    if (!context.loc.isAr) return option;
    final lower = option.toLowerCase().trim();
    if (lower == 'biscuit') return 'بسكوت';
    if (lower.contains('extra topping')) return 'إضافات';
    if (lower.contains('extra shot')) return 'شوت إضافي';
    if (lower.contains('milk')) return 'حليب';
    return option;
  }

  /// Translates order statuses, always honouring the active locale.
  static String translateStatus(BuildContext context, String status) {
    final s = status.toLowerCase().trim();
    final isArabic = context.loc.isAr;

    if (isArabic) {
      if (s == 'preparing') return 'جاري التحضير';
      if (s == 'paid') return 'تم الدفع';
      if (s == 'completed') return 'تم الاستلام';
      if (s == 'pending') return 'قيد الانتظار';
      if (s == 'ready') return 'جاهز للاستلام';
      if (s == 'delivered') return 'تم التسليم';
      if (s == 'cancelled') return 'ملغي';
    } else {
      if (s == 'preparing') return 'Preparing';
      if (s == 'paid') return 'Paid';
      if (s == 'completed') return 'Completed';
      if (s == 'pending') return 'Pending';
      if (s == 'ready') return 'Ready';
      if (s == 'delivered') return 'Delivered';
      if (s == 'cancelled') return 'Cancelled';
    }

    return status;
  }
}
