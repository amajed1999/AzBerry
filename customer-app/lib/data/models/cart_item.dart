import 'product.dart';

class CartItem {
  final String uid; // unique line id
  final Product product;
  final ProductSize? size;
  final List<ProductAddon> addons;
  final int quantity;
  final String? notes;

  CartItem({
    required this.uid,
    required this.product,
    this.size,
    this.addons = const [],
    this.quantity = 1,
    this.notes,
  });

  /// Price of a single unit (base + size modifier + addons).
  num get unitPrice {
    final sizeMod = size?.priceModifier ?? 0;
    final addonsSum = addons.fold<num>(0, (s, a) => s + a.price);
    return product.basePrice + sizeMod + addonsSum;
  }

  num get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        uid: uid,
        product: product,
        size: size,
        addons: addons,
        quantity: quantity ?? this.quantity,
        notes: notes,
      );

  /// Serialized addons for order_items.addons_json
  List<Map<String, dynamic>> addonsJson() =>
      addons.map((a) => {'id': a.id, 'name': a.nameAr, 'price': a.price}).toList();
}
