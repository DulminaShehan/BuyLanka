import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class ShopRepository {
  final SupabaseClient _client;

  ShopRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch the seller's active shop
  Future<ShopModel?> getShopBySellerId(String sellerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.shopsTable)
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (data == null) return null;
      return ShopModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create default shop if seller does not have one yet
  Future<ShopModel> createDefaultShop(String sellerId, String businessName) async {
    final slug = businessName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final payload = {
      'seller_id': sellerId,
      'name': businessName,
      'slug': '$slug-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'description': 'Welcome to $businessName on BuyLanka!',
      'status': 'approved',
      'is_open': true,
      'opening_time': '08:00 AM',
      'closing_time': '10:00 PM',
      'rating': 5.0,
      'total_reviews': 0,
    };

    final data = await _client
        .from(SupabaseConstants.shopsTable)
        .insert(payload)
        .select()
        .single();

    return ShopModel.fromJson(data);
  }

  /// Update shop profile & settings
  Future<ShopModel> updateShop(ShopModel shop) async {
    final payload = {
      'name': shop.name,
      'description': shop.description,
      'logo_url': shop.logoUrl,
      'banner_url': shop.bannerUrl,
      'address': shop.address,
      'city': shop.city,
      'district': shop.district,
      'contact_phone': shop.contactPhone,
      'is_open': shop.isOpen,
      'opening_time': shop.openingTime,
      'closing_time': shop.closingTime,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final data = await _client
        .from(SupabaseConstants.shopsTable)
        .update(payload)
        .eq('id', shop.id)
        .select()
        .single();

    return ShopModel.fromJson(data);
  }

  /// Quick toggle for shop Open / Closed status
  Future<void> toggleShopOpenStatus(String shopId, bool isOpen) async {
    await _client
        .from(SupabaseConstants.shopsTable)
        .update({
          'is_open': isOpen,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shopId);
  }
}
