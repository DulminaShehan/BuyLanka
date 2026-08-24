import 'order_item_model.dart';
import 'profile_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String? shopId;
  final double totalAmount;
  final double deliveryFee;
  final double discountAmount;
  final String paymentMethod; // 'cod', 'card', 'bank_transfer', 'koko', 'mintpay'
  final String paymentStatus; // 'pending', 'paid', 'failed', 'refunded'
  final String orderStatus; // 'pending', 'accepted', 'preparing', 'ready_for_pickup', 'shipped', 'delivered', 'cancelled'
  final Map<String, dynamic> shippingAddress;
  final String? customerNotes;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final ProfileModel? customer;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.shopId,
    required this.totalAmount,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.shippingAddress = const {},
    this.customerNotes,
    this.createdAt,
    this.items = const [],
    this.customer,
  });

  String get customerName {
    if (customer?.fullName != null && customer!.fullName.isNotEmpty) {
      return customer!.fullName;
    }
    return shippingAddress['recipient_name'] as String? ?? 'Customer';
  }

  String get customerPhone {
    if (customer?.phoneNumber != null && customer!.phoneNumber!.isNotEmpty) {
      return customer!.phoneNumber!;
    }
    return shippingAddress['phone_number'] as String? ?? shippingAddress['phone'] as String? ?? '—';
  }

  String get deliveryAddressText {
    final address = shippingAddress['address'] as String? ?? shippingAddress['street_address'] as String?;
    final city = shippingAddress['city'] as String?;
    if (address != null && city != null) return '$address, $city';
    return address ?? city ?? 'Colombo, Sri Lanka';
  }

  int get totalItemCount {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      parsedItems = (json['order_items'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      shopId: json['shop_id'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      orderStatus: json['order_status'] as String? ?? 'pending',
      shippingAddress: json['shipping_address'] is Map<String, dynamic>
          ? json['shipping_address'] as Map<String, dynamic>
          : {},
      customerNotes: json['customer_notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      items: parsedItems,
      customer: json['customer'] != null ? ProfileModel.fromJson(json['customer'] as Map<String, dynamic>) : null,
    );
  }

  OrderModel copyWith({
    String? orderStatus,
    String? paymentStatus,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      shopId: shopId,
      totalAmount: totalAmount,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      shippingAddress: shippingAddress,
      customerNotes: customerNotes,
      createdAt: createdAt,
      items: items ?? this.items,
      customer: customer,
    );
  }
}
