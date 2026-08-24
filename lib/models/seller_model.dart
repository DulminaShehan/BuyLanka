import 'profile_model.dart';

class SellerModel {
  final String id;
  final String businessName;
  final String? businessRegistrationNumber;
  final String? nicNumber;
  final String verificationStatus; // 'pending', 'verified', 'rejected', 'suspended'
  final double commissionRate;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankBranch;
  final DateTime? createdAt;
  final ProfileModel? profile;

  const SellerModel({
    required this.id,
    required this.businessName,
    this.businessRegistrationNumber,
    this.nicNumber,
    required this.verificationStatus,
    required this.commissionRate,
    this.bankName,
    this.bankAccountNumber,
    this.bankBranch,
    this.createdAt,
    this.profile,
  });

  bool get isVerified => verificationStatus == 'verified';

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String? ?? '',
      businessRegistrationNumber: json['business_registration_number'] as String?,
      nicNumber: json['nic_number'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 10.0,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankBranch: json['bank_branch'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      profile: json['profile'] != null ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'business_registration_number': businessRegistrationNumber,
      'nic_number': nicNumber,
      'verification_status': verificationStatus,
      'commission_rate': commissionRate,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_branch': bankBranch,
    };
  }
}
