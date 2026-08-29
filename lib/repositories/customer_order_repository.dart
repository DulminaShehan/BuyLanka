import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class CustomerOrderRepository {
  final SupabaseClient _client;

  CustomerOrderRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Place new customer order in Supabase
  Future<OrderModel> placeOrder({
    required String customerId,
    required String shopId,
    required Map<String, dynamic> shippingAddress,
    required List<CartItemModel> items,
    String? customerNotes,
    String paymentMethod = 'cod',
    double deliveryFee = 250.0,
    double discountAmount = 0.0,
  }) async {
    final rand = Random().nextInt(9000) + 1000;
    final orderNumber = 'BLK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}$rand';

    // Calculate subtotal
    final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final totalAmount = subtotal + deliveryFee - discountAmount;

    // 1. Insert order record
    final orderData = await _client
        .from(SupabaseConstants.ordersTable)
        .insert({
          'order_number': orderNumber,
          'customer_id': customerId,
          'shop_id': shopId,
          'total_amount': totalAmount,
          'delivery_fee': deliveryFee,
          'discount_amount': discountAmount,
          'payment_method': paymentMethod,
          'payment_status': 'pending',
          'order_status': 'pending',
          'shipping_address': shippingAddress,
          'customer_notes': customerNotes,
        })
        .select('*, shop:${SupabaseConstants.shopsTable}(*)')
        .single();

    final orderId = orderData['id'] as String;

    // 2. Insert order items
    final itemPayloads = items.map((i) {
      return {
        'order_id': orderId,
        'product_id': i.product.id,
        'product_title': i.product.title,
        'unit_price': i.product.price,
        'quantity': i.quantity,
        'total_price': i.totalPrice,
      };
    }).toList();

    await _client.from(SupabaseConstants.orderItemsTable).insert(itemPayloads);

    // 3. Create initial delivery record
    try {
      final pickupAddress = orderData['shop']?['address'] ?? 'Restaurant Address';
      final dropoffAddress = shippingAddress['street_address'] ?? shippingAddress['address'] ?? 'Customer Address';

      await _client.from(SupabaseConstants.deliveriesTable).insert({
        'order_id': orderId,
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
        'delivery_status': 'unassigned',
      });
    } catch (_) {}

    // 4. Create in-app notification
    try {
      await _client.from(SupabaseConstants.notificationsTable).insert({
        'user_id': customerId,
        'title': 'Order Placed 🎉',
        'message': 'Your order #$orderNumber has been placed and sent to the restaurant.',
        'type': 'order',
        'data': {'order_id': orderId},
      });
    } catch (_) {}

    return OrderModel.fromJson(orderData);
  }

  /// Fetch orders placed by customer
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ordersTable)
          .select('''
            *,
            order_items:${SupabaseConstants.orderItemsTable}(*),
            shop:${SupabaseConstants.shopsTable}!shop_id(*)
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (data as List).map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch single order details with items and delivery
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ordersTable)
          .select('''
            *,
            order_items:${SupabaseConstants.orderItemsTable}(*),
            shop:${SupabaseConstants.shopsTable}!shop_id(*)
          ''')
          .eq('id', orderId)
          .maybeSingle();

      if (data == null) return null;
      return OrderModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Realtime stream of order changes
  Stream<List<Map<String, dynamic>>> streamOrder(String orderId) {
    return _client
        .from(SupabaseConstants.ordersTable)
        .stream(primaryKey: ['id'])
        .eq('id', orderId);
  }

  /// Realtime stream of assigned delivery record
  Stream<List<Map<String, dynamic>>> streamDelivery(String orderId) {
    return _client
        .from(SupabaseConstants.deliveriesTable)
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId);
  }

  /// Realtime stream of live rider GPS location coordinates
  Stream<List<Map<String, dynamic>>> streamRiderLocation(String deliveryId) {
    return _client
        .from(SupabaseConstants.riderLocationsTable)
        .stream(primaryKey: ['id'])
        .eq('delivery_id', deliveryId)
        .order('created_at', ascending: false)
        .limit(1);
  }
}
