// Driver-app data models.

enum DStatus { pending, confirmed, preparing, ready, onTheWay, delivered, cancelled }

DStatus dStatusFrom(String s) => switch (s) {
      'pending' => DStatus.pending,
      'confirmed' => DStatus.confirmed,
      'preparing' => DStatus.preparing,
      'ready' => DStatus.ready,
      'on_the_way' => DStatus.onTheWay,
      'delivered' => DStatus.delivered,
      'cancelled' => DStatus.cancelled,
      _ => DStatus.pending,
    };

extension DStatusX on DStatus {
  String get labelAr => switch (this) {
        DStatus.pending => 'قيد الانتظار',
        DStatus.confirmed => 'مؤكّد',
        DStatus.preparing => 'قيد التحضير',
        DStatus.ready => 'جاهز للاستلام',
        DStatus.onTheWay => 'بالطريق',
        DStatus.delivered => 'تم التسليم',
        DStatus.cancelled => 'ملغى',
      };
}

class Driver {
  final String id;
  final String? branchId;
  final bool isOnline;
  final bool isActive;
  final num rating;
  final String? vehicleType;
  final String? plateNumber;

  Driver({
    required this.id,
    this.branchId,
    required this.isOnline,
    required this.isActive,
    required this.rating,
    this.vehicleType,
    this.plateNumber,
  });

  factory Driver.fromMap(Map<String, dynamic> m) => Driver(
        id: m['id'] as String,
        branchId: m['branch_id'] as String?,
        isOnline: (m['is_online'] as bool?) ?? false,
        isActive: (m['is_active'] as bool?) ?? true,
        rating: (m['rating'] as num?) ?? 5,
        vehicleType: m['vehicle_type'] as String?,
        plateNumber: m['plate_number'] as String?,
      );
}

class DeliveryOrder {
  final String id;
  final String branchId;
  final String? driverId;
  final DStatus status;
  final String orderType;
  final num total;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final String? notes;
  // joined
  final String? branchName;
  final String? customerName;
  final String? customerPhone;
  final String? addressText;
  final double? addrLat;
  final double? addrLng;

  DeliveryOrder({
    required this.id,
    required this.branchId,
    this.driverId,
    required this.status,
    required this.orderType,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.notes,
    this.branchName,
    this.customerName,
    this.customerPhone,
    this.addressText,
    this.addrLat,
    this.addrLng,
  });

  factory DeliveryOrder.fromMap(Map<String, dynamic> m) {
    final branch = m['branches'] as Map<String, dynamic>?;
    final user = m['users'] as Map<String, dynamic>?;
    final addr = m['addresses'] as Map<String, dynamic>?;
    return DeliveryOrder(
      id: m['id'] as String,
      branchId: m['branch_id'] as String,
      driverId: m['driver_id'] as String?,
      status: dStatusFrom(m['status'] as String),
      orderType: m['order_type'] as String? ?? 'delivery',
      total: (m['total'] as num?) ?? 0,
      paymentMethod: m['payment_method'] as String? ?? 'cash',
      paymentStatus: m['payment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(m['created_at'] as String),
      notes: m['notes'] as String?,
      branchName: branch?['name_ar'] as String?,
      customerName: user?['name'] as String?,
      customerPhone: user?['phone'] as String?,
      addressText: addr?['address_text'] as String?,
      addrLat: (addr?['lat'] as num?)?.toDouble(),
      addrLng: (addr?['lng'] as num?)?.toDouble(),
    );
  }
}

const paymentLabels = {
  'cash': 'نقداً',
  'zaincash': 'ZainCash',
  'asiahawala': 'AsiaHawala',
  'fastpay': 'FastPay',
  'qicard': 'Qi Card',
  'card': 'بطاقة',
  'wallet': 'محفظة',
};
