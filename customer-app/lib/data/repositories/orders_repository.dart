import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Result of a `validate-promo` preview call.
class PromoPreview {
  final bool valid;
  final String message;
  final num discount;
  final bool deliveryWaived;
  PromoPreview({
    required this.valid,
    required this.message,
    this.discount = 0,
    this.deliveryWaived = false,
  });
}

/// Server-computed order result returned by the `place-order` Edge Function.
class PlacedOrder {
  final String orderId;
  final num subtotal;
  final num discount;
  final num deliveryFee;
  final num tax;
  final num total;

  PlacedOrder({
    required this.orderId,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.tax,
    required this.total,
  });
}

/// Raised when the `place-order` function rejects the request (e.g. below
/// minimum order, invalid promo, product unavailable). [message] is Arabic.
class PlaceOrderException implements Exception {
  final String message;
  PlaceOrderException(this.message);
  @override
  String toString() => message;
}

class OrdersRepository {
  final SupabaseClient _db;
  OrdersRepository(this._db);

  /// Places an order through the secure `place-order` Edge Function.
  ///
  /// The client sends only item references (no prices). The function recomputes
  /// every price with the service role, validates the promo, enforces the branch
  /// minimum, then creates the order + items and returns the authoritative total.
  Future<PlacedOrder> placeOrder({
    required String branchId,
    required List<CartItem> items,
    required String orderType, // 'delivery' | 'pickup'
    required String paymentMethod,
    String? promoCode,
    String? addressId,
    String? notes,
  }) async {
    late final dynamic data;
    try {
      final res = await _db.functions.invoke('place-order', body: {
        'branch_id': branchId,
        'order_type': orderType,
        'payment_method': paymentMethod,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
        if (addressId != null) 'address_id': addressId,
        if (notes != null) 'notes': notes,
        'items': items
            .map((c) => {
                  'product_id': c.product.id,
                  'size_id': c.size?.id,
                  'addon_ids': c.addons.map((a) => a.id).toList(),
                  'quantity': c.quantity,
                  'notes': c.notes,
                })
            .toList(),
      });
      data = res.data;
    } on FunctionException catch (e) {
      // Non-2xx responses (e.g. below minimum, invalid promo) land here; the
      // function body is in `details` and carries the Arabic `error` message.
      final details = e.details;
      final msg = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'تعذّر إنشاء الطلب';
      throw PlaceOrderException(msg);
    }

    if (data is Map && data['error'] != null) {
      throw PlaceOrderException(data['error'].toString());
    }
    if (data is! Map || data['order_id'] == null) {
      throw PlaceOrderException('تعذّر إنشاء الطلب');
    }

    final b = (data['breakdown'] as Map?) ?? const {};
    return PlacedOrder(
      orderId: data['order_id'] as String,
      subtotal: (b['subtotal'] as num?) ?? 0,
      discount: (b['discount'] as num?) ?? 0,
      deliveryFee: (b['delivery_fee'] as num?) ?? 0,
      tax: (b['tax'] as num?) ?? 0,
      total: (b['total'] as num?) ?? 0,
    );
  }

  /// Previews a promo code (before checkout) via the `validate-promo` function.
  /// Returns the parsed body: { valid, message, discount, delivery_waived, ... }.
  Future<PromoPreview> validatePromo({
    required String code,
    required String branchId,
    required num subtotal,
  }) async {
    try {
      final res = await _db.functions.invoke('validate-promo', body: {
        'code': code,
        'branch_id': branchId,
        'subtotal': subtotal,
      });
      final d = res.data;
      if (d is! Map) return PromoPreview(valid: false, message: 'استجابة غير صالحة');
      return PromoPreview(
        valid: d['valid'] == true,
        message: (d['message'] ?? '').toString(),
        discount: (d['discount'] as num?) ?? 0,
        deliveryWaived: d['delivery_waived'] == true,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = (details is Map && details['message'] != null)
          ? details['message'].toString()
          : 'تعذّر التحقّق من الكود';
      return PromoPreview(valid: false, message: msg);
    }
  }

  Future<AppOrder> byId(String id) async {
    final row = await _db.from('orders').select().eq('id', id).single();
    return AppOrder.fromMap(row);
  }

  /// Realtime stream of a single order's status changes.
  Stream<AppOrder> watch(String id) {
    return _db
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => AppOrder.fromMap(rows.first));
  }

  Future<List<AppOrder>> myOrders(String userId) async {
    final rows = await _db
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AppOrder.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
