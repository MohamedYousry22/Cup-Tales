import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_state.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/models/offer_model.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  void loadHomeData() async {
    if (isClosed) return;
    emit(HomeLoading());
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      final response = await Supabase.instance.client.from('offers').select();
      final banners = (response as List)
          .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final mockProducts = [
        const ProductEntity(
          id: '1',
          name: 'Espresso',
          categoryId: 'dummy_cat',
          description: 'Strong and bold.',
          imageUrl: 'assets/images/products/espresso.png',
          priceS: 2.5,
        ),
        const ProductEntity(
          id: '2',
          name: 'Cappuccino',
          categoryId: 'dummy_cat',
          description: 'Classic Italian coffee.',
          imageUrl: 'assets/images/products/cappuccino.png',
          priceS: 3.5,
        ),
        const ProductEntity(
          id: '3',
          name: 'Latte',
          categoryId: 'dummy_cat',
          description: 'Smooth and milky.',
          imageUrl: 'assets/images/products/latte.png',
          priceS: 4.0,
        ),
      ];
      final mockCategories = [
        const CategoryEntity(
          id: '1',
          imagePath: 'assets/images/categories/fresh_juice.jpg',
        ),
        const CategoryEntity(
          id: '2',
          imagePath: 'assets/images/categories/hot_drinks.jpg',
        ),
        const CategoryEntity(
          id: '3',
          imagePath: 'assets/images/categories/iced_drinks.jpg',
        ),
        const CategoryEntity(
          id: '4',
          imagePath: 'assets/images/categories/milkshake.jpg',
        ),
        const CategoryEntity(
          id: '5',
          imagePath: 'assets/images/categories/mix_soda.jpg',
        ),
        const CategoryEntity(
          id: '6',
          imagePath: 'assets/images/categories/smoothie.jpg',
        ),
        const CategoryEntity(
          id: '7',
          imagePath: 'assets/images/categories/sundae.jpg',
        ),
      ];

      if (isClosed) return;
      emit(
        HomeLoaded(
          banners: banners,
          featuredProducts: mockProducts,
          categories: mockCategories,
          selectedCategoryId: mockCategories.first.id,
        ),
      );
    } catch (e) {
      if (!isClosed) emit(HomeError(e.toString()));
    }
  }

  void selectCategory(String id) {
    if (!isClosed && state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(selectedCategoryId: id));
    }
  }
}
