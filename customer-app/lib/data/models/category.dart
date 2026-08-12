import 'package:azberry_customer/core/i18n.dart';

class Category {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int sortOrder;

  String get name => AppLocale.isEn ? nameEn : nameAr;

  Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.imageUrl,
    required this.sortOrder,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        imageUrl: m['image_url'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}
