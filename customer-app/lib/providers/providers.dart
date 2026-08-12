import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/branch.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/models/address.dart';
import '../data/models/banner.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/orders_repository.dart';
import '../data/repositories/account_repository.dart';

/// Supabase client (initialized in main()).
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final catalogRepoProvider =
    Provider((ref) => CatalogRepository(ref.watch(supabaseProvider)));
final ordersRepoProvider =
    Provider((ref) => OrdersRepository(ref.watch(supabaseProvider)));
final accountRepoProvider =
    Provider((ref) => AccountRepository(ref.watch(supabaseProvider)));

/// Auth state stream (session changes).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

/// Branches list.
final branchesProvider = FutureProvider<List<Branch>>(
  (ref) => ref.watch(catalogRepoProvider).branches(),
);

/// Currently selected branch (defaults to the first once branches load).
final selectedBranchProvider = StateProvider<Branch?>((ref) => null);

/// Categories list.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepoProvider).categories(),
);

/// Promotional banners for the home slider.
final bannersProvider = FutureProvider<List<AppBanner>>(
  (ref) => ref.watch(catalogRepoProvider).banners(),
);

/// Products for the selected branch.
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final branch = ref.watch(selectedBranchProvider);
  if (branch == null) return [];
  return ref.watch(catalogRepoProvider).products(branchId: branch.id);
});

/// Selected category filter (null = all).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// The signed-in user's profile row (name, points, wallet, language).
final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider);
  final db = ref.watch(supabaseProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return null;
  return db.from('users').select().eq('id', uid).maybeSingle();
});

/// The signed-in user's saved addresses.
final addressesProvider = FutureProvider<List<Address>>(
  (ref) {
    ref.watch(authStateProvider);
    return ref.watch(accountRepoProvider).addresses();
  },
);

/// The signed-in user's favourite products (full objects for the grid).
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) {
  ref.watch(favoriteIdsProvider);
  return ref.watch(accountRepoProvider).favoriteProducts();
});

/// Set of favourited product ids, with optimistic toggle.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this.ref) : super({}) {
    load();
  }
  final Ref ref;

  Future<void> load() async {
    state = await ref.read(accountRepoProvider).favoriteIds();
  }

  bool isFavorite(String productId) => state.contains(productId);

  Future<void> toggle(String productId) async {
    final making = !state.contains(productId);
    // optimistic update
    if (making) {
      state = {...state, productId};
    } else {
      state = {...state}..remove(productId);
    }
    await ref.read(accountRepoProvider).toggleFavorite(productId, making);
  }
}

final favoriteIdsProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  ref.watch(authStateProvider); // reload on login/logout
  return FavoritesNotifier(ref);
});
