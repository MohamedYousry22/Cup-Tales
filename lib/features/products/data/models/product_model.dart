import 'dart:convert';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.nameAr,
    required super.categoryId,
    required super.description,
    required super.imageUrl,
    super.priceS,
    super.priceM,
    super.priceL,
    super.branchId,
    super.optionPrices = const {},
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedOptionPrices = const {};
    var raw = json['option_prices'];
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map) {
      parsedOptionPrices = raw
          .map((k, v) => MapEntry(k.toString(), (v as num? ?? 0).toDouble()));
    }

    final nameEn = json['name_en'] as String?;
    final name = json['name'] as String?;

    return ProductModel(
      id: json['id'] as String,
      name: (nameEn != null && nameEn.trim().isNotEmpty)
          ? nameEn.trim()
          : (name != null && name.trim().isNotEmpty)
              ? name.trim()
              : 'Unknown Product',
      nameAr: json['name_ar'] as String?,
      categoryId: json['category_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      priceS: (json['price_s'] as num?)?.toDouble(),
      priceM: (json['price_m'] as num? ?? json['price'] as num?)?.toDouble(),
      priceL: (json['price_l'] as num?)?.toDouble(),
      branchId: json['branch_id']?.toString(),
      optionPrices: parsedOptionPrices,
    );
  }
}
