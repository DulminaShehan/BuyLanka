import 'package:buylanka/models/profile_model.dart';

class RiderModel {
  final String id;
  final String vehicleType; // 'motorcycle', 'three_wheeler', 'car', 'van', 'bicycle'
  final String vehicleNumber;
  final String drivingLicenseNumber;
  final String? assignedZone;
  final String availabilityStatus; // 'available', 'busy', 'offline'
  final String verificationStatus; // 'pending', 'approved', 'rejected', 'suspended'
  final double rating;
  final int totalDeliveries;
  final bool isOnline;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdatedAt;
  final ProfileModel? profile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RiderModel({
    required this.id,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.drivingLicenseNumber,
    this.assignedZone,
    this.availabilityStatus = 'offline',
    this.verificationStatus = 'pending',
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.isOnline = false,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdatedAt,
    this.profile,
    this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => verificationStatus == 'approved';
  bool get isAvailableForOrders => isOnline && availabilityStatus == 'available';

  String get vehicleTypeDisplay {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return 'Motorbike';
      case 'three_wheeler':
        return 'Tuk-Tuk / Three Wheeler';
      case 'car':
        return 'Car';
      case 'van':
        return 'Delivery Van';
      case 'bicycle':
        return 'Bicycle';
      default:
        return vehicleType.toUpperCase();
    }
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      vehicleType: json['vehicle_type'] as String? ?? 'motorcycle',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      drivingLicenseNumber: json['driving_license_number'] as String? ?? '',
      assignedZone: json['assigned_zone'] as String?,
      availabilityStatus: json['availability_status'] as String? ?? 'offline',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: (json['total_deliveries'] as num?)?.toInt() ?? 0,
      isOnline: (json['is_online'] as bool?) ?? (json['availability_status'] == 'available'),
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      lastLocationUpdatedAt: json['last_location_updated_at'] != null
          ? DateTime.tryParse(json['last_location_updated_at'].toString())
          : null,
      profile: json['profile'] != null ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  RiderModel copyWith({
    String? vehicleType,
    String? vehicleNumber,
    String? drivingLicenseNumber,
    String? assignedZone,
    String? availabilityStatus,
    String? verificationStatus,
    double? rating,
    int? totalDeliveries,
    bool? isOnline,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdatedAt,
    ProfileModel? profile,
  }) {
    return RiderModel(
      id: id,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      assignedZone: assignedZone ?? this.assignedZone,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isOnline: isOnline ?? this.isOnline,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdatedAt: lastLocationUpdatedAt ?? this.lastLocationUpdatedAt,
      profile: profile ?? this.profile,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'driving_license_number': drivingLicenseNumber,
      'assigned_zone': assignedZone,
      'availability_status': availabilityStatus,
      'verification_status': verificationStatus,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'is_online': isOnline,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'last_location_updated_at': lastLocationUpdatedAt?.toIso8601String(),
    };
  }
}
