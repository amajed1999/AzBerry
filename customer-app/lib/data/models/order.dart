import 'package:azberry_customer/core/i18n.dart';

enum OrderStatus { pending, confirmed, preparing, ready, onTheWay, delivered, cancelled }

OrderStatus orderStatusFromString(String s) => switch (s) {
      'pending' => OrderStatus.pending,
      'confirmed' => OrderStatus.confirmed,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'on_the_way' => OrderStatus.onTheWay,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };

extension OrderStatusX on OrderStatus {
  String get labelAr => switch (this) {
        OrderStatus.pending => tr('قيد الانتظار'),
        OrderStatus.confirmed => tr('مؤكّد'),
        OrderStatus.preparing => tr('قيد التحضير'),
        OrderStatus.ready => tr('جاهز'),
        OrderStatus.onTheWay => tr('السائق بالطريق'),
        OrderStatus.delivered => tr('تم التسليم'),
        OrderStatus.cancelled => tr('ملغى'),
      };
}

class AppOrder {
  final String id;
  final String branchId;
  final OrderStatus status;
  final num subtotal;
  final num deliveryFee;
  final num tax;
  final num discount;
  final num total;
  final String orderType;
  final String paymentMethod;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.branchId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.orderType,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory AppOrder.fromMap(Map<String, dynamic> m) => AppOrder(
        id: m['id'] as String,
        branchId: m['branch_id'] as String,
        status: orderStatusFromString(m['status'] as String),
        subtotal: (m['subtotal'] as num?) ?? 0,
        deliveryFee: (m['delivery_fee'] as num?) ?? 0,
        tax: (m['tax'] as num?) ?? 0,
        discount: (m['discount'] as num?) ?? 0,
        total: (m['total'] as num?) ?? 0,
        orderType: m['order_type'] as String? ?? 'delivery',
        paymentMethod: m['payment_method'] as String? ?? 'cash',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
