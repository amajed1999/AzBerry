class Branch {
  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final String? phone;
  final num deliveryFee;
  final num minOrder;
  final bool isActive;
  final bool isBusy;

  Branch({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
    this.phone,
    required this.deliveryFee,
    required this.minOrder,
    required this.isActive,
    required this.isBusy,
  });

  factory Branch.fromMap(Map<String, dynamic> m) => Branch(
        id: m['id'] as String,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        phone: m['phone'] as String?,
        deliveryFee: (m['delivery_fee'] as num?) ?? 0,
        minOrder: (m['min_order'] as num?) ?? 0,
        isActive: (m['is_active'] as bool?) ?? true,
        isBusy: (m['is_busy'] as bool?) ?? false,
      );
}
