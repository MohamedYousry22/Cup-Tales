import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/product_model.dart';

abstract class ProductsRemoteDS {
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
}

class ProductsRemoteDSImpl implements ProductsRemoteDS {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .order('created_at', ascending: true);

    final rawProducts = response as List<dynamic>;

    return rawProducts
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .where((product) => product.basePrice > 0)
        .toList();
  }
}
