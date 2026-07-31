import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/offer_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<OfferEntity> banners;
  final List<ProductEntity> featuredProducts;
  final List<CategoryEntity> categories;
  final String selectedCategoryId;

  const HomeLoaded({
    required this.banners,
    required this.featuredProducts,
    required this.categories,
    required this.selectedCategoryId,
  });

  HomeLoaded copyWith({
    List<OfferEntity>? banners,
    List<ProductEntity>? featuredProducts,
    List<CategoryEntity>? categories,
    String? selectedCategoryId,
  }) {
    return HomeLoaded(
      banners: banners ?? this.banners,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }

  @override
  List<Object?> get props => [
        banners,
        featuredProducts,
        categories,
        selectedCategoryId,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
