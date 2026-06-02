// ignore_for_file: avoid_print
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Production tokens extracted from lib/core/config/supabase_config.dart
  const supabaseUrl = 'https://xidugzdzigyezserlhlj.supabase.co';
  const supabaseKey = 'sb_publishable_l7sZcgZzKYUHtRyvG2wCGA_AVGJ6N0R';

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Fetching categories...');
  final data = await client.from('categories').select();

  print(
      'Found ${data.length} categories. Checking for missing or incorrect Arabic names...');

  // Define a mapping for expected translations
  final Map<String, String> expectedTranslations = {
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

  for (var category in data) {
    final id = category['id'];
    final nameEn = category['name_en'] ?? category['name'] ?? '';
    final nameAr = category['name_ar'];
    final lowerNameEn = nameEn.toString().toLowerCase();

    String? newTranslation;

    // Determine the expected translation based on English name
    for (var entry in expectedTranslations.entries) {
      if (lowerNameEn.contains(entry.key)) {
        newTranslation = entry.value;
        break;
      }
    }

    // Fallback for new categories
    newTranslation ??= 'صنف جديد';

    // Check if update is needed
    if (nameAr == null ||
        nameAr.toString().trim().isEmpty ||
        nameAr.toString().trim() != newTranslation) {
      print(
          'Category ID $id ($nameEn) needs update. Current: "$nameAr", Expected: "$newTranslation"');

      try {
        await client
            .from('categories')
            .update({'name_ar': newTranslation}).eq('id', id);
        print('  -> Updated to: $newTranslation');
      } catch (e) {
        print('  -> Failed to update: $e');
      }
    } else {
      print(
          'Category ID $id ($nameEn) already has correct Arabic translation: $nameAr');
    }
  }

  print('Patch complete.');
  exit(0);
}
