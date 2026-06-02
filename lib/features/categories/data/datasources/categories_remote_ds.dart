import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/category_model.dart';
import 'package:flutter/foundation.dart';

abstract class CategoriesRemoteDS {
  Future<List<CategoryModel>> getCategories();
}

class CategoriesRemoteDSImpl implements CategoriesRemoteDS {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<CategoryModel>> getCategories() async {
    // 1. Fetch the raw categories
    final categoriesResponse = await _client
        .from('categories')
        .select()
        .order('created_at', ascending: true);

    debugPrint('DEBUG: raw categoriesResponse from Supabase count: ${categoriesResponse.length}');
    if (categoriesResponse.isNotEmpty) {
      debugPrint('DEBUG: First category keys: ${categoriesResponse.first.keys}');
      debugPrint('DEBUG: First category data: ${categoriesResponse.first}');
    }

    // 2. Fetch all potential Category Covers from the products table
    // A cover is defined as a product missing all size prices.
    final productsResponse = await _client
        .from('products')
        .select('name, name_ar, image_url, category_id')
        .isFilter('price_s', null)
        .isFilter('price_m', null)
        .isFilter('price_l', null);

    final rawCategories = categoriesResponse as List<dynamic>;
    final potentialCovers = productsResponse as List<dynamic>;

    // 3. Map JSON into CategoryModels while injecting the matching cover image
    return rawCategories.map((rawCat) {
      final jsonCat = rawCat as Map<String, dynamic>;
      final catId = jsonCat['id'].toString();
      final rawCatNameEn = (jsonCat['name_en']?.toString() ?? jsonCat['name']?.toString() ?? '');
      final rawCatNameAr = jsonCat['name_ar']?.toString() ?? '';
      
      String catNameAr = rawCatNameAr.trim();
      final catNameEnLower = rawCatNameEn.toLowerCase().trim();

      // --- Fallback Translation Logic ---
      final Map<String, String> translationMap = {
        'iced': 'المشروبات المثلجة',
        'hot': 'المشروبات الساخنة',
        'fresh juice': 'العصائر الطبيعية',
        'smoothie': 'سموثي',
        'dessert': 'الحلويات',
        'sweets': 'الحلويات',
        'bakery': 'المخبوزات',
        'frappe': 'فرابيه',
        'milkshake': 'ميلك شيك',
        'mix soda': 'ميكس صودا',
        'sundae': 'صانداي',
      };

      // If translated name is empty, null, or same as English, try fallback
      if (catNameAr.isEmpty || catNameAr.toLowerCase() == catNameEnLower) {
        for (var entry in translationMap.entries) {
          if (catNameEnLower.contains(entry.key)) {
            catNameAr = entry.value;
            jsonCat['name_ar'] = catNameAr; // Update json for the model
            break;
          }
        }
      }
      // ----------------------------------

      // Find a matching cover image in the products list
      String? matchedImageUrl;

      for (var cover in potentialCovers) {
        final coverCatId = cover['category_id']?.toString() ?? '';
        final coverNameEn =
            (cover['name']?.toString() ?? '').toLowerCase().trim();
        final coverNameAr = (cover['name_ar']?.toString() ?? '').trim();

        // Match Rule: Same category_id AND (Names match exactly OR Cover Name contains Category Name OR Category Name contains Cover Name)
        bool enMatch = catNameEnLower.isNotEmpty &&
            coverNameEn.isNotEmpty &&
            (coverNameEn.contains(catNameEnLower) ||
                catNameEnLower.contains(coverNameEn));
        bool arMatch = catNameAr.isNotEmpty &&
            coverNameAr.isNotEmpty &&
            (coverNameAr.contains(catNameAr) ||
                catNameAr.contains(coverNameAr));

        if (coverCatId == catId && (enMatch || arMatch)) {
          matchedImageUrl = cover['image_url']?.toString();
          break;
        }
      }

      // If we found a dynamic cover, inject it. Otherwise keep whatever primitive string was there.
      if (matchedImageUrl != null && matchedImageUrl.isNotEmpty) {
        jsonCat['image'] = matchedImageUrl;
      }

      return CategoryModel.fromJson(jsonCat);
    }).toList();
  }
}
