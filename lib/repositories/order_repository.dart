import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch orders for a shop with line items and customer details
  Future<List<OrderModel>> getOrdersByShop(String shopId, {String? statusFilter}) async {
    try {
      var query = _client
          .from(SupabaseConstants.ordersTable)
          .select('''
            *,
            order_items:${SupabaseConstants.orderItemsTable}(*),
            customer:${SupabaseConstants.profilesTable}!customer_id(*)
          ''')
          .eq('shop_id', shopId);

      if (statusFilter != null && statusFilter != 'all') {
        if (statusFilter == 'active') {
          query = query.inFilter('order_status', ['pending', 'accepted', 'preparing', 'ready_for_pickup']);
        } else if (statusFilter == 'history') {
          query = query.inFilter('order_status', ['shipped', 'delivered', 'cancelled', 'returned']);
        } else {
          query = query.eq('order_status', statusFilter);
        }
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Realtime stream of orders for the shop
  Stream<List<Map<String, dynamic>>> streamShopOrders(String shopId) {
    return _client
        .from(SupabaseConstants.ordersTable)
        .stream(primaryKey: ['id'])
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client
        .from(SupabaseConstants.ordersTable)
        .update({
          'order_status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  /// Accept an incoming order
  Future<void> acceptOrder(String orderId) async {
    await updateOrderStatus(orderId, 'accepted');
  }

  /// Start preparing food
  Future<void> startPreparing(String orderId) async {
    await updateOrderStatus(orderId, 'preparing');
  }

  /// Mark order ready for delivery rider pickup
  Future<void> markReadyForPickup(String orderId) async {
    await updateOrderStatus(orderId, 'ready_for_pickup');
  }

  /// Reject / Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await updateOrderStatus(orderId, 'cancelled');
  }
}
