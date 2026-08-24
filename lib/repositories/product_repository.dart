import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch all products for a specific shop
  Future<List<ProductModel>> getProductsByShop(String shopId, {String? categoryId, String? search}) async {
    try {
      var query = _client
          .from(SupabaseConstants.productsTable)
          .select('*, category:${SupabaseConstants.categoriesTable}(*)')
          .eq('shop_id', shopId);

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('title', '%${search.trim()}%');
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch active platform categories
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

  /// Create a new product / food menu item
  Future<ProductModel> createProduct(ProductModel product) async {
    final slug = product.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final payload = {
      'shop_id': product.shopId,
      'category_id': product.categoryId,
      'title': product.title.trim(),
      'slug': '$slug-${DateTime.now().millisecondsSinceEpoch % 100000}',
      'description': product.description?.trim(),
      'price': product.price,
      'original_price': product.originalPrice,
      'stock_quantity': product.stockQuantity,
      'sku': product.sku?.trim(),
      'images': product.images,
      'status': product.isAvailable ? 'published' : 'draft',
      'is_featured': product.isFeatured,
      'is_available': product.isAvailable,
      'preparation_time_minutes': product.preparationTimeMinutes,
    };

    final data = await _client
        .from(SupabaseConstants.productsTable)
        .insert(payload)
        .select('*, category:${SupabaseConstants.categoriesTable}(*)')
        .single();

    return ProductModel.fromJson(data);
  }

  /// Update an existing product
  Future<ProductModel> updateProduct(ProductModel product) async {
    final payload = {
      'category_id': product.categoryId,
      'title': product.title.trim(),
      'description': product.description?.trim(),
      'price': product.price,
      'original_price': product.originalPrice,
      'stock_quantity': product.stockQuantity,
      'sku': product.sku?.trim(),
      'images': product.images,
      'status': product.isAvailable ? 'published' : 'draft',
      'is_featured': product.isFeatured,
      'is_available': product.isAvailable,
      'preparation_time_minutes': product.preparationTimeMinutes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final data = await _client
        .from(SupabaseConstants.productsTable)
        .update(payload)
        .eq('id', product.id)
        .select('*, category:${SupabaseConstants.categoriesTable}(*)')
        .single();

    return ProductModel.fromJson(data);
  }

  /// Quick toggle for product availability
  Future<void> toggleProductAvailability(String productId, bool isAvailable) async {
    await _client
        .from(SupabaseConstants.productsTable)
        .update({
          'is_available': isAvailable,
          'status': isAvailable ? 'published' : 'draft',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    await _client
        .from(SupabaseConstants.productsTable)
        .delete()
        .eq('id', productId);
  }
}
