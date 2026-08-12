import 'package:azberry_customer/core/i18n.dart';

class ProductSize {
  final String id;
  final String sizeName;
  final num priceModifier;
  ProductSize({required this.id, required this.sizeName, required this.priceModifier});

  factory ProductSize.fromMap(Map<String, dynamic> m) => ProductSize(
        id: m['id'] as String,
        sizeName: m['size_name'] as String,
        priceModifier: (m['price_modifier'] as num?) ?? 0,
      );

  String get labelAr => switch (sizeName) {
        'small' => 'صغير',
        'medium' => 'وسط',
        'large' => 'كبير',
        _ => sizeName,
      };

  String get labelEn => switch (sizeName) {
        'small' => 'Small',
        'medium' => 'Medium',
        'large' => 'Large',
        _ => sizeName,
      };

  String get label => AppLocale.isEn ? labelEn : labelAr;
}

class ProductAddon {
  final String id;
  final String nameAr;
  final String nameEn;
  final num price;
  ProductAddon({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
  });

  factory ProductAddon.fromMap(Map<String, dynamic> m) => ProductAddon(
        id: m['id'] as String,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        price: (m['price'] as num?) ?? 0,
      );

  String get name => AppLocale.isEn ? nameEn : nameAr;
}

class Product {
  final String id;
  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? imageUrl;
  final num basePrice;
  final int? calories;
  final List<ProductSize> sizes;
  final List<ProductAddon> addons;

  /// Display name in the active language.
  String get name => AppLocale.isEn ? nameEn : nameAr;

  Product({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.imageUrl,
    required this.basePrice,
    this.calories,
    this.sizes = const [],
    this.addons = const [],
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        categoryId: m['category_id'] as String,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        descriptionAr: m['description_ar'] as String?,
        imageUrl: m['image_url'] as String?,
        basePrice: (m['base_price'] as num?) ?? 0,
        calories: m['calories'] as int?,
        sizes: ((m['product_sizes'] as List?) ?? [])
            .map((e) => ProductSize.fromMap(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.priceModifier.compareTo(b.priceModifier)),
        addons: ((m['product_addons'] as List?) ?? [])
            .map((e) => ProductAddon.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}
