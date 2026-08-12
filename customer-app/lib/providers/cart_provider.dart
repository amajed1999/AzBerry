import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(CartItem item) => state = [...state, item];

  void remove(String uid) =>
      state = state.where((c) => c.uid != uid).toList();

  void setQuantity(String uid, int qty) {
    if (qty <= 0) {
      remove(uid);
      return;
    }
    state = [
      for (final c in state)
        if (c.uid == uid) c.copyWith(quantity: qty) else c
    ];
  }

  void clear() => state = [];

  num get subtotal => state.fold<num>(0, (s, c) => s + c.lineTotal);
  int get count => state.fold<int>(0, (s, c) => s + c.quantity);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

/// Convenience: total item count for the badge.
final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (s, c) => s + c.quantity);
});

final cartSubtotalProvider = Provider<num>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<num>(0, (s, c) => s + c.lineTotal);
});
