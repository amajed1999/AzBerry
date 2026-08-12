import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address.dart';
import '../models/product.dart';

/// Addresses, favorites, reviews, and profile edits for the signed-in user.
class AccountRepository {
  final SupabaseClient _db;
  AccountRepository(this._db);

  String? get _uid => _db.auth.currentUser?.id;

  // ---- Profile -------------------------------------------------------------
  Future<void> updateProfile({String? name, String? language}) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('users').update({
      if (name != null) 'name': name,
      if (language != null) 'language': language,
    }).eq('id', uid);
  }

  // ---- Addresses -----------------------------------------------------------
  Future<List<Address>> addresses() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _db
        .from('addresses')
        .select()
        .eq('user_id', uid)
        .order('is_default', ascending: false)
        .order('created_at');
    return (rows as List).map((e) => Address.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAddress({
    String? id,
    String? label,
    required double lat,
    required double lng,
    String? addressText,
    String? building,
    String? notes,
    bool isDefault = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    if (isDefault) {
      // Only one default per user.
      await _db.from('addresses').update({'is_default': false}).eq('user_id', uid);
    }

    final payload = {
      'user_id': uid,
      'label': label,
      'lat': lat,
      'lng': lng,
      'address_text': addressText,
      'building': building,
      'notes': notes,
      'is_default': isDefault,
    };

    if (id == null) {
      await _db.from('addresses').insert(payload);
    } else {
      await _db.from('addresses').update(payload).eq('id', id);
    }
  }

  Future<void> deleteAddress(String id) async {
    await _db.from('addresses').delete().eq('id', id);
  }

  // ---- Favorites -----------------------------------------------------------
  Future<Set<String>> favoriteIds() async {
    final uid = _uid;
    if (uid == null) return {};
    final rows = await _db.from('favorites').select('product_id').eq('user_id', uid);
    return (rows as List).map((e) => (e as Map<String, dynamic>)['product_id'] as String).toSet();
  }

  Future<List<Product>> favoriteProducts() async {
    final uid = _uid;
    if (uid == null) return [];
    final favs = await _db.from('favorites').select('product_id').eq('user_id', uid);
    final ids = (favs as List).map((e) => (e as Map<String, dynamic>)['product_id'] as String).toList();
    if (ids.isEmpty) return [];
    final rows = await _db
        .from('products')
        .select('*, product_sizes(*), product_addons(*)')
        .inFilter('id', ids);
    return (rows as List).map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleFavorite(String productId, bool makeFavorite) async {
    final uid = _uid;
    if (uid == null) return;
    if (makeFavorite) {
      await _db.from('favorites').upsert(
        {'user_id': uid, 'product_id': productId},
        onConflict: 'user_id,product_id',
      );
    } else {
      await _db.from('favorites').delete().eq('user_id', uid).eq('product_id', productId);
    }
  }

  // ---- Reviews -------------------------------------------------------------
  Future<bool> hasReview(String orderId) async {
    final row = await _db.from('reviews').select('id').eq('order_id', orderId).maybeSingle();
    return row != null;
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('reviews').upsert({
      'order_id': orderId,
      'user_id': uid,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'order_id');
  }
}
