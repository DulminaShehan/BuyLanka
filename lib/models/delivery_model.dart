import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/models/rider_model.dart';

class DeliveryModel {
  final String id;
  final String orderId;
  final String? riderId;
  final String pickupAddress;
  final String dropoffAddress;
  final String deliveryStatus; // 'assigned', 'accepted', 'going_to_pickup', 'arrived_at_pickup', 'picked_up', 'going_to_customer', 'arrived_at_customer', 'delivered', 'cancelled'
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? deliveryNotes;
  final String? proofOfDeliveryUrl;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final double distanceKm;
  final int estimatedMinutes;
  final OrderModel? order;
  final RiderModel? rider;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    this.riderId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.deliveryStatus = 'assigned',
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryNotes,
    this.proofOfDeliveryUrl,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.distanceKm = 3.5,
    this.estimatedMinutes = 15,
    this.order,
    this.rider,
    this.createdAt,
    this.updatedAt,
  });

  // Stage Checkers
  bool get isAssigned => deliveryStatus == 'assigned';
  bool get isAccepted => deliveryStatus == 'accepted';
  bool get isGoingToPickup => deliveryStatus == 'going_to_pickup';
  bool get isArrivedAtPickup => deliveryStatus == 'arrived_at_pickup';
  bool get isPickedUp => deliveryStatus == 'picked_up';
  bool get isGoingToCustomer => deliveryStatus == 'going_to_customer';
  bool get isArrivedAtCustomer => deliveryStatus == 'arrived_at_customer';
  bool get isDelivered => deliveryStatus == 'delivered';
  bool get isCancelled => deliveryStatus == 'cancelled' || deliveryStatus == 'failed';

  bool get isBeforePickup => isAssigned || isAccepted || isGoingToPickup || isArrivedAtPickup;
  bool get isAfterPickup => isPickedUp || isGoingToCustomer || isArrivedAtCustomer;
  bool get isActive => !isDelivered && !isCancelled;

  // Next valid status transition in the 8-step workflow
  String? get nextStatus {
    switch (deliveryStatus) {
      case 'assigned':
        return 'accepted';
      case 'accepted':
        return 'going_to_pickup';
      case 'going_to_pickup':
        return 'arrived_at_pickup';
      case 'arrived_at_pickup':
        return 'picked_up';
      case 'picked_up':
        return 'going_to_customer';
      case 'going_to_customer':
        return 'arrived_at_customer';
      case 'arrived_at_customer':
        return 'delivered';
      default:
        return null;
    }
  }

  String get nextActionLabel {
    switch (deliveryStatus) {
      case 'assigned':
        return 'Accept Delivery';
      case 'accepted':
        return 'Start Heading to Restaurant';
      case 'going_to_pickup':
        return 'Arrived at Restaurant';
      case 'arrived_at_pickup':
        return 'Confirm Food Pickup';
      case 'picked_up':
        return 'Start Heading to Customer';
      case 'going_to_customer':
        return 'Arrived at Customer';
      case 'arrived_at_customer':
        return 'Confirm Delivery Handover';
      default:
        return 'Completed';
    }
  }

  String get statusDisplay {
    switch (deliveryStatus) {
      case 'assigned':
        return 'Assigned to You';
      case 'accepted':
        return 'Delivery Accepted';
      case 'going_to_pickup':
        return 'Heading to Restaurant';
      case 'arrived_at_pickup':
        return 'At Restaurant';
      case 'picked_up':
        return 'Food Picked Up';
      case 'going_to_customer':
        return 'Delivering to Customer';
      case 'arrived_at_customer':
        return 'Arrived at Customer';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return deliveryStatus.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      riderId: json['rider_id'] as String?,
      pickupAddress: json['pickup_address'] as String? ?? 'Restaurant Location',
      dropoffAddress: json['dropoff_address'] as String? ?? 'Customer Location',
      deliveryStatus: json['delivery_status'] as String? ?? 'assigned',
      assignedAt: json['assigned_at'] != null ? DateTime.tryParse(json['assigned_at'].toString()) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at'].toString()) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
      deliveryNotes: json['delivery_notes'] as String?,
      proofOfDeliveryUrl: json['proof_of_delivery_url'] as String?,
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble() ?? 6.9271,
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble() ?? 79.8612,
      dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble() ?? 6.8905,
      dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble() ?? 79.8732,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 3.5,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 15,
      order: json['order'] != null ? OrderModel.fromJson(json['order'] as Map<String, dynamic>) : null,
      rider: json['rider'] != null ? RiderModel.fromJson(json['rider'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  DeliveryModel copyWith({
    String? deliveryStatus,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? deliveryNotes,
    String? proofOfDeliveryUrl,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    double? distanceKm,
    int? estimatedMinutes,
    OrderModel? order,
  }) {
    return DeliveryModel(
      id: id,
      orderId: orderId,
      riderId: riderId,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      proofOfDeliveryUrl: proofOfDeliveryUrl ?? this.proofOfDeliveryUrl,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      order: order ?? this.order,
      rider: rider,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'rider_id': riderId,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'delivery_status': deliveryStatus,
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'delivery_notes': deliveryNotes,
      'proof_of_delivery_url': proofOfDeliveryUrl,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
      'distance_km': distanceKm,
      'estimated_minutes': estimatedMinutes,
    };
  }
}
