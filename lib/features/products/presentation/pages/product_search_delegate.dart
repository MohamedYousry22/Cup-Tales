import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/widgets/antigravity_loader.dart';
import '../../data/models/product_model.dart';
import '../widgets/product_grid_card.dart';

class ProductSearchDelegate extends SearchDelegate<ProductEntity?> {
  ProductSearchDelegate();

  @override
  String get searchFieldLabel => 'Search / بحث'; // Default static fallback

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          context.loc.searchProduct,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final supabase = Supabase.instance.client;
    // Querying across English and Arabic names
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('products').select().or(
          'name.ilike.%$query%,name_en.ilike.%$query%,name_ar.ilike.%$query%'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: AntigravityLoaderCore(size: 60),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text(context.loc.error));
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return Center(
            child: Text(
              context.loc.noProductsFound,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final products = data
            .map((d) => ProductModel.fromJson(d))
            .where((p) => p.basePrice > 0)
            .toList();

        if (products.isEmpty) {
          return Center(
            child: Text(
              context.loc.noProductsFound,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductGridCard(product: products[index]);
          },
        );
      },
    );
  }
}
