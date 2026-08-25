import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/review_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class ReviewRepository {
  final SupabaseClient _client;

  ReviewRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Submit review for a completed order
  Future<bool> submitReview(ReviewModel review) async {
    try {
      await _client.from(SupabaseConstants.reviewsTable).insert(review.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get reviews for a specific shop
  Future<List<ReviewModel>> getShopReviews(String shopId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.reviewsTable)
          .select('*, customer:${SupabaseConstants.profilesTable}!customer_id(*)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      return (data as List).map((r) => ReviewModel.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if customer already reviewed an order
  Future<bool> hasReviewedOrder(String orderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.reviewsTable)
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }
}
