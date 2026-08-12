import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner.dart';
import '../models/branch.dart';
import '../models/category.dart';
import '../models/product.dart';

class CatalogRepository {
  final SupabaseClient _db;
  CatalogRepository(this._db);

  Future<List<AppBanner>> banners() async {
    final rows = await _db
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((e) => AppBanner.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Branch>> branches() async {
    final rows = await _db
        .from('branches')
        .select()
        .eq('is_active', true)
        .order('name_ar');
    return (rows as List)
        .map((e) => Branch.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> categories() async {
    final rows = await _db
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Products available at a given branch (respects branch_products availability).
  Future<List<Product>> products({required String branchId}) async {
    // Products flagged available for this branch.
    final available = await _db
        .from('branch_products')
        .select('product_id, is_available')
        .eq('branch_id', branchId)
        .eq('is_available', true);
    final ids = (available as List)
        .map((e) => (e as Map<String, dynamic>)['product_id'] as String)
        .toList();

    final query = _db
        .from('products')
        .select('*, product_sizes(*), product_addons(*)')
        .eq('is_active', true);

    final rows = ids.isEmpty
        // Fallback: if a branch has no explicit mapping yet, show all active
        // products so the menu is never empty during onboarding.
        ? await query.order('sort_order')
        : await query.inFilter('id', ids).order('sort_order');

    return (rows as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
