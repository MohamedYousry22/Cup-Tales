import 'package:equatable/equatable.dart';

class SupabaseCartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final double basePrice;
  final String image;
  final int quantity;
  final String? productNameAr;

  /// Size/variant key selected by the user (e.g. 'S', 'M', 'L').
  /// Always nullable — products without variants will have null here.
  final String? selectedSize;

  /// Customizable option choices (e.g., {'الحجم': 'وسط'}).
  final Map<String, String> selectedOptions;

  /// List of selected add-ons (e.g. [{'name': 'جبنة إضافية', 'price': 15}]).
  final List<Map<String, dynamic>> selectedAddons;

  /// Category-level single option selected by the user.
  final String? selectedOption;

  const SupabaseCartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.basePrice,
    required this.image,
    required this.quantity,
    this.productNameAr,
    this.selectedSize,
    this.selectedOptions = const {},
    this.selectedAddons = const [],
    this.selectedOption,
  });

  factory SupabaseCartItem.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as Map<String, dynamic>?;

    final double price = ((json['price'] ??
            products?['price'] ??
            products?['price_m'] ??
            0.0) as num)
        .toDouble();

    final double basePrice = ((json['base_price'] ??
            products?['price'] ??
            products?['price_m'] ??
            price) as num)
        .toDouble();

    // Parse options safely: expect a Map<String, String>
    Map<String, String> parsedOptions = const {};
    final rawOptions = json['selected_options'];
    if (rawOptions is Map) {
      parsedOptions = rawOptions.map((key, value) =>
          MapEntry(key.toString().trim(), value.toString().trim()));
    }

    // Parse addons safely: expect List of Maps
    List<Map<String, dynamic>> parsedAddons = const [];
    final rawAddons = json['selected_addons'];
    if (rawAddons is List) {
      parsedAddons =
          rawAddons.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return SupabaseCartItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: products?['name_en'] as String? ??
          products?['name'] as String? ??
          json['product_name_en'] as String? ??
          json['product_name'] as String? ??
          'Unknown Product',
      price: price,
      basePrice: basePrice,
      image: products?['image'] as String? ??
          products?['image_url'] as String? ??
          json['image'] as String? ??
          '',
      quantity: ((json['quantity'] as num?) ?? 1).toInt(),
      productNameAr:
          products?['name_ar'] as String? ?? json['product_name_ar'] as String?,
      selectedSize: json['selected_size'] as String?,
      selectedOptions: parsedOptions,
      selectedAddons: parsedAddons,
      selectedOption: json['selected_option'] as String?,
    );
  }

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name_en': productName,
        'product_name': productName,
        'product_name_ar': productNameAr,
        'base_price': basePrice,
        'price': price,
        'image': image,
        'quantity': quantity,
        'selected_size': selectedSize,
        'selected_options': selectedOptions,
        'selected_addons': selectedAddons,
        'selected_option': selectedOption,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        price,
        basePrice,
        image,
        quantity,
        selectedSize,
        selectedOptions,
        selectedAddons,
        selectedOption,
      ];
}
