import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class DriverRepository {
  final SupabaseClient _db;
  DriverRepository(this._db);

  String? get _uid => _db.auth.currentUser?.id;

  /// The driver row for the signed-in user (null if this user isn't a driver).
  Future<Driver?> me() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _db.from('drivers').select().eq('user_id', uid).maybeSingle();
    return row == null ? null : Driver.fromMap(row);
  }

  Future<void> setOnline(bool online) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('drivers').update({'is_online': online}).eq('user_id', uid);
  }

  Future<void> updateLocation(double lat, double lng) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .from('drivers')
        .update({'current_lat': lat, 'current_lng': lng}).eq('user_id', uid);
  }

  static const _select =
      '*, branches(name_ar), users(name, phone), addresses(address_text, lat, lng)';

  /// Unassigned orders in the driver's branch that are ready to be picked up.
  Future<List<DeliveryOrder>> available(String branchId) async {
    final rows = await _db
        .from('orders')
        .select(_select)
        .eq('branch_id', branchId)
        .isFilter('driver_id', null)
        .inFilter('status', ['confirmed', 'preparing', 'ready'])
        .order('created_at');
    return (rows as List)
        .map((e) => DeliveryOrder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// The driver's current active order (assigned, not finished).
  Future<DeliveryOrder?> activeOrder(String driverId) async {
    final rows = await _db
        .from('orders')
        .select(_select)
        .eq('driver_id', driverId)
        .not('status', 'in', '(delivered,cancelled)')
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty
        ? null
        : DeliveryOrder.fromMap(list.first as Map<String, dynamic>);
  }

  /// Claim an unassigned order (allowed by RLS orders_driver_claim).
  Future<bool> accept(String orderId, String driverId) async {
    final res = await _db
        .from('orders')
        .update({'driver_id': driverId})
        .eq('id', orderId)
        .isFilter('driver_id', null)
        .select('id');
    return (res as List).isNotEmpty;
  }

  Future<DeliveryOrder?> byId(String id) async {
    final row = await _db.from('orders').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : DeliveryOrder.fromMap(row);
  }

  Future<void> setStatus(String orderId, String status) async {
    await _db.from('orders').update({'status': status}).eq('id', orderId);
  }

  /// Today's delivered orders: count + cash collected.
  Future<({int count, num earnings, num cash})> todaySummary(String driverId) async {
    final start = DateTime.now();
    final midnight = DateTime(start.year, start.month, start.day);
    final rows = await _db
        .from('orders')
        .select('total, payment_method')
        .eq('driver_id', driverId)
        .eq('status', 'delivered')
        .gte('delivered_at', midnight.toIso8601String());
    var count = 0;
    num earnings = 0;
    num cash = 0;
    for (final r in rows as List) {
      count++;
      final t = (r['total'] as num?) ?? 0;
      earnings += t;
      if (r['payment_method'] == 'cash') cash += t;
    }
    return (count: count, earnings: earnings, cash: cash);
  }
}
