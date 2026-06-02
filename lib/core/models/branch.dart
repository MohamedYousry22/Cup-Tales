import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String id;
  final String nameEn;
  final String nameAr;
  final String areaEn;
  final String areaAr;
  final String location;
  final bool active;

  const Branch({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.areaEn,
    required this.areaAr,
    required this.location,
    this.active = true,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    final String nameEn = map['name'] as String? ?? '';
    final String nameAr = map['name_ar'] as String? ?? nameEn;
    return Branch(
      id: map['id'] as String? ?? '',
      nameEn: nameEn,
      nameAr: nameAr,
      areaEn: map['area_en'] as String? ?? '',
      areaAr: map['area_ar'] as String? ?? '',
      location: map['location'] as String? ?? map['map_url'] as String? ?? '',
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nameAr,
      'location': location,
      'active': active,
    };
  }

  @override
  List<Object?> get props =>
      [id, nameEn, nameAr, areaEn, areaAr, location, active];
}

List<Branch> appBranches = [
  const Branch(
    id: 'rehab',
    nameEn: 'Rehab Branch',
    nameAr: 'فرع الرحاب',
    areaEn: 'New Cairo',
    areaAr: 'القاهرة الجديدة',
    location: 'https://maps.app.goo.gl/NAZnJfaY99HrSBYJ9',
  ),
  const Branch(
    id: 'mahalla1',
    nameEn: 'Mahalla 1 (Tanta Road)',
    nameAr: 'فرع المحلة 1 - طريق طنطا',
    areaEn: 'El Mahalla El Kubra',
    areaAr: 'المحلة الكبرى',
    location: 'https://maps.app.goo.gl/rRnhstcoyHXMKyaG8',
  ),
  const Branch(
    id: 'mahalla2',
    nameEn: 'Mahalla 2 (Reda Hafez St)',
    nameAr: 'فرع المحلة 2 - ش رضا حافظ',
    areaEn: 'El Mahalla El Kubra',
    areaAr: 'المحلة الكبرى',
    location: 'https://maps.app.goo.gl/kTpifykykRoc9DRFA',
  ),
];
