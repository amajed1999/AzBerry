class Address {
  final String id;
  final String? label;
  final double lat;
  final double lng;
  final String? addressText;
  final String? building;
  final String? notes;
  final bool isDefault;

  Address({
    required this.id,
    this.label,
    required this.lat,
    required this.lng,
    this.addressText,
    this.building,
    this.notes,
    required this.isDefault,
  });

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        id: m['id'] as String,
        label: m['label'] as String?,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        addressText: m['address_text'] as String?,
        building: m['building'] as String?,
        notes: m['notes'] as String?,
        isDefault: (m['is_default'] as bool?) ?? false,
      );
}
