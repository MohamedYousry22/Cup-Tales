import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String categoryId;
  final String description;
  final String imageUrl;
  final double? priceS;
  final double? priceM;
  final double? priceL;
  final String? branchId;
  final Map<String, double> optionPrices;

  const ProductEntity({
    required this.id,
    required this.name,
    this.nameAr,
    required this.categoryId,
    required this.description,
    required this.imageUrl,
    this.priceS,
    this.priceM,
    this.priceL,
    this.branchId,
    this.optionPrices = const {},
  });

  // Helper to safely get the "starting" price or base price
  double get basePrice {
    if (optionPrices.isNotEmpty) {
      double minPrice = double.infinity;
      for (final p in optionPrices.values) {
        if (p > 0 && p < minPrice) {
          minPrice = p;
        }
      }
      if (minPrice != double.infinity) {
        return minPrice.roundToDouble();
      }
    }
    return (priceS ?? priceM ?? priceL ?? 0.0).roundToDouble();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        categoryId,
        description,
        imageUrl,
        priceS,
        priceM,
        priceL,
        branchId,
        optionPrices,
      ];
}
