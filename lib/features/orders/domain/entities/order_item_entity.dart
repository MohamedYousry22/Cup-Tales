import 'package:equatable/equatable.dart';

/// Represents a single product line inside a stored order's `items` JSONB array.
///
/// Field names follow Dart camelCase conventions; the DB column names (used in
/// [OrderModel.fromJson] / [OrderModel.toJson]) are documented next to each field.
class OrderItemEntity extends Equatable {
  /// DB key: `product_id`
  final String productId;

  /// DB key: `product_name_en`
  final String productNameEn;

  /// DB key: `product_name_ar` — null when no Arabic translation exists.
  final String? productNameAr;

  /// DB key: `image_url` — null when no image was stored.
  final String? imageUrl;

  /// DB key: `unit_price` — price per single unit.
  final double unitPrice;

  /// DB key: `base_price` — original product base price before add-ons.
  final double basePrice;

  /// DB key: `quantity`
  final int quantity;

  /// DB key: `total_price` — unitPrice × quantity (pre-calculated).
  final double totalPrice;

  /// DB key: `selected_size` — Size variant selected at order time (e.g. 'S', 'M', 'L').
  /// Nullable — products without sizes omit this field.
  final String? selectedSize;

  /// DB key: `selected_options` — Customizable option choices (e.g., {'الحجم': 'وسط'}).
  final Map<String, String> selectedOptions;

  /// DB key: `selected_addons` — Selected add-ons (e.g. [{'name': 'جبنة', 'price': 15}]).
  final List<Map<String, dynamic>> selectedAddons;

  /// DB key: `selected_option` — Category-level single option selected at order time.
  final String? selectedOption;

  const OrderItemEntity({
    required this.productId,
    required this.productNameEn,
    this.productNameAr,
    this.imageUrl,
    required this.unitPrice,
    required this.basePrice,
    required this.quantity,
    required this.totalPrice,
    this.selectedSize,
    this.selectedOptions = const {},
    this.selectedAddons = const [],
    this.selectedOption,
  });

  // ── Display helpers ─────────────────────────────────────────────────────────

  /// Returns [productNameEn] in Title Case.
  ///
  /// Handles ALL-CAPS legacy strings from the DB:
  ///   "MINT LEMON" → "Mint Lemon"
  ///   "Kiwi Mango" → "Kiwi Mango"  (already correct, unchanged)
  String get displayNameEn {
    if (productNameEn.isEmpty) return 'Unknown Product';
    // Only convert if the string is all-uppercase (legacy data); leave mixed case alone.
    final isAllCaps = productNameEn == productNameEn.toUpperCase();
    if (!isAllCaps) return productNameEn;
    return productNameEn
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Returns [productNameAr] when valid, otherwise falls back to [displayNameEn].
  ///
  /// "Valid" means: non-null, non-empty, and not the literal string "null".
  String get displayNameAr {
    final ar = productNameAr;
    if (ar == null || ar.trim().isEmpty || ar.trim().toLowerCase() == 'null') {
      return displayNameEn;
    }
    return ar.trim();
  }

  /// Locale-aware name: pass `isArabic` from context.
  String displayName(bool isArabic) => isArabic ? displayNameAr : displayNameEn;

  /// Whether a valid image URL is available.
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        productId,
        productNameEn,
        productNameAr,
        imageUrl,
        unitPrice,
        basePrice,
        quantity,
        totalPrice,
        selectedSize,
        selectedOptions,
        selectedAddons,
        selectedOption,
      ];
}
