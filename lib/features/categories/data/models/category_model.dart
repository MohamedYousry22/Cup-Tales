import '../../domain/entities/category_entity.dart';
import 'package:flutter/foundation.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.image,
    super.branchId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final model = CategoryModel(
      id: json['id'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      image: json['image'] as String? ?? '',
      branchId: json['branch_id']?.toString(),
    );
    debugPrint(
        'DEBUG: CategoryModel created: id=${model.id}, en=${model.nameEn}, ar=${model.nameAr}');
    return model;
  }
}
