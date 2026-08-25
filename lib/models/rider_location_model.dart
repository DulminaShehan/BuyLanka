class RiderLocationModel {
  final String id;
  final String riderId;
  final String? deliveryId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime createdAt;

  const RiderLocationModel({
    required this.id,
    required this.riderId,
    this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.createdAt,
  });

  factory RiderLocationModel.fromJson(Map<String, dynamic> json) {
    return RiderLocationModel(
      id: json['id'] as String,
      riderId: json['rider_id'] as String,
      deliveryId: json['delivery_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_id': riderId,
      'delivery_id': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
    };
  }
}
