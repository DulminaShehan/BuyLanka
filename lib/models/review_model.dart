import 'package:buylanka/models/profile_model.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String? shopId;
  final String? riderId;
  final int rating;
  final String? comment;
  final ProfileModel? customer;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.shopId,
    this.riderId,
    required this.rating,
    this.comment,
    this.customer,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] as String,
      shopId: json['shop_id'] as String?,
      riderId: json['rider_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      customer: json['customer'] != null ? ProfileModel.fromJson(json['customer'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'shop_id': shopId,
      'rider_id': riderId,
      'rating': rating,
      'comment': comment,
    };
  }
}
