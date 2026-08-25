import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class FavoriteRepository {
  final SupabaseClient _client;

  FavoriteRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch favorite shops for customer
  Future<List<ShopModel>> getFavoriteShops(String customerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('shop:${SupabaseConstants.shopsTable}(*)')
          .eq('customer_id', customerId)
          .not('shop_id', 'is', null);

      return (data as List)
          .where((item) => item['shop'] != null)
          .map((item) => ShopModel.fromJson(item['shop'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch favorite products for customer
  Future<List<ProductModel>> getFavoriteProducts(String customerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('product:${SupabaseConstants.productsTable}(*, category:${SupabaseConstants.categoriesTable}(*))')
          .eq('customer_id', customerId)
          .not('product_id', 'is', null);

      return (data as List)
          .where((item) => item['product'] != null)
          .map((item) => ProductModel.fromJson(item['product'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Toggle favorite status of a shop
  Future<bool> toggleFavoriteShop(String customerId, String shopId) async {
    try {
      final existing = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('id')
          .eq('customer_id', customerId)
          .eq('shop_id', shopId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(SupabaseConstants.customerFavoritesTable)
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        await _client.from(SupabaseConstants.customerFavoritesTable).insert({
          'customer_id': customerId,
          'shop_id': shopId,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status of a product
  Future<bool> toggleFavoriteProduct(String customerId, String productId) async {
    try {
      final existing = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('id')
          .eq('customer_id', customerId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(SupabaseConstants.customerFavoritesTable)
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        await _client.from(SupabaseConstants.customerFavoritesTable).insert({
          'customer_id': customerId,
          'product_id': productId,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if shop is favorited
  Future<bool> isShopFavorite(String customerId, String shopId) async {
    try {
      final existing = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('id')
          .eq('customer_id', customerId)
          .eq('shop_id', shopId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if product is favorited
  Future<bool> isProductFavorite(String customerId, String productId) async {
    try {
      final existing = await _client
          .from(SupabaseConstants.customerFavoritesTable)
          .select('id')
          .eq('customer_id', customerId)
          .eq('product_id', productId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      return false;
    }
  }
}
