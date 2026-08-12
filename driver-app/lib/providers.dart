import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/driver_repository.dart';
import 'data/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final driverRepoProvider = Provider((ref) => DriverRepository(ref.watch(supabaseProvider)));

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange,
);

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

/// The driver profile (null while loading / if not a driver).
final myDriverProvider = FutureProvider<Driver?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(driverRepoProvider).me();
});

/// Local online state mirror (kept in sync with the driver row).
final onlineProvider = StateProvider<bool>((ref) => false);

/// Available (unassigned) orders for the driver's branch.
final availableOrdersProvider = FutureProvider.autoDispose((ref) async {
  final driver = await ref.watch(myDriverProvider.future);
  if (driver == null || driver.branchId == null) return const <DeliveryOrder>[];
  return ref.watch(driverRepoProvider).available(driver.branchId!);
});

/// The driver's current active order.
final activeOrderProvider = FutureProvider.autoDispose((ref) async {
  final driver = await ref.watch(myDriverProvider.future);
  if (driver == null) return null;
  return ref.watch(driverRepoProvider).activeOrder(driver.id);
});

/// A single order by id (for the detail screen).
final orderByIdProvider =
    FutureProvider.autoDispose.family<DeliveryOrder?, String>((ref, id) {
  return ref.watch(driverRepoProvider).byId(id);
});

/// Today's summary.
final summaryProvider =
    FutureProvider.autoDispose<({int count, num earnings, num cash})>((ref) async {
  final driver = await ref.watch(myDriverProvider.future);
  if (driver == null) return (count: 0, earnings: 0, cash: 0);
  return ref.watch(driverRepoProvider).todaySummary(driver.id);
});
