class ShopModel {
  final String id;
  final String sellerId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? address;
  final String? city;
  final String? district;
  final String? contactPhone;
  final String status; // 'pending', 'approved', 'suspended', 'rejected'
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShopModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.city,
    this.district,
    this.contactPhone,
    required this.status,
    required this.rating,
    required this.totalReviews,
    this.isOpen = true,
    this.openingTime,
    this.closingTime,
    this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => status == 'approved';

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String? ?? 'Shop',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      contactPhone: json['contact_phone'] as String?,
      status: json['status'] as String? ?? 'approved',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
      openingTime: json['opening_time'] as String? ?? '08:00 AM',
      closingTime: json['closing_time'] as String? ?? '10:00 PM',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  ShopModel copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? address,
    String? city,
    String? district,
    String? contactPhone,
    String? status,
    bool? isOpen,
    String? openingTime,
    String? closingTime,
  }) {
    return ShopModel(
      id: id,
      sellerId: sellerId,
      name: name ?? this.name,
      slug: slug,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      rating: rating,
      totalReviews: totalReviews,
      isOpen: isOpen ?? this.isOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'slug': slug,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'address': address,
      'city': city,
      'district': district,
      'contact_phone': contactPhone,
      'status': status,
      'is_open': isOpen,
      'opening_time': openingTime,
      'closing_time': closingTime,
    };
  }
}
