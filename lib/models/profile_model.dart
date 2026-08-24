class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role; // 'admin', 'seller', 'rider', 'customer'
  final String status; // 'active', 'suspended', 'pending'
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSeller => role == 'seller';
  bool get isActive => status == 'active';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'customer',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
    };
  }
}
