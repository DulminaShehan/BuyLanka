import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class CustomerRepository {
  final SupabaseClient _client;

  CustomerRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch active categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final data = await _client
          .from(SupabaseConstants.categoriesTable)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (data as List).map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch approved shops (optionally filtered by category or search)
  Future<List<ShopModel>> getShops({String? search, String? categoryId}) async {
    try {
      var query = _client
          .from(SupabaseConstants.shopsTable)
          .select()
          .eq('status', 'approved');

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim()}%');
      }

      final data = await query.order('rating', ascending: false);
      return (data as List).map((s) => ShopModel.fromJson(s as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch popular / top-rated shops
  Future<List<ShopModel>> getPopularShops({int limit = 6}) async {
    try {
      final data = await _client
          .from(SupabaseConstants.shopsTable)
          .select()
          .eq('status', 'approved')
          .order('rating', ascending: false)
          .limit(limit);

      return (data as List).map((s) => ShopModel.fromJson(s as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch single shop details by ID
  Future<ShopModel?> getShopById(String shopId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.shopsTable)
          .select()
          .eq('id', shopId)
          .maybeSingle();

      if (data == null) return null;
      return ShopModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Fetch published products of a shop
  Future<List<ProductModel>> getProductsByShop(String shopId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.productsTable)
          .select('*, category:${SupabaseConstants.categoriesTable}(*)')
          .eq('shop_id', shopId)
          .eq('status', 'published')
          .order('title', ascending: true);

      return (data as List).map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch featured / popular recommended dishes across Sri Lanka
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final data = await _client
          .from(SupabaseConstants.productsTable)
          .select('*, category:${SupabaseConstants.categoriesTable}(*)')
          .eq('status', 'published')
          .eq('is_featured', true)
          .limit(limit);

      if ((data as List).isEmpty) {
        // Fallback: fetch any published products
        final fallback = await _client
            .from(SupabaseConstants.productsTable)
            .select('*, category:${SupabaseConstants.categoriesTable}(*)')
            .eq('status', 'published')
            .limit(limit);
        return (fallback as List).map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
      }

      return (data as List).map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search food dishes and shops
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final data = await _client
          .from(SupabaseConstants.productsTable)
          .select('*, category:${SupabaseConstants.categoriesTable}(*)')
          .eq('status', 'published')
          .ilike('title', '%${query.trim()}%')
          .limit(20);

      return (data as List).map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
