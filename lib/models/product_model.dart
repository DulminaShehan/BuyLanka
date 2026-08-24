import 'category_model.dart';

class ProductModel {
  final String id;
  final String shopId;
  final String? categoryId;
  final String title;
  final String slug;
  final String? description;
  final double price;
  final double? originalPrice;
  final int stockQuantity;
  final String? sku;
  final List<String> images;
  final String status; // 'published', 'draft', 'archived', 'pending_approval'
  final bool isFeatured;
  final bool isAvailable;
  final int preparationTimeMinutes;
  final CategoryModel? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.title,
    required this.slug,
    this.description,
    required this.price,
    this.originalPrice,
    this.stockQuantity = 0,
    this.sku,
    this.images = const [],
    this.status = 'published',
    this.isFeatured = false,
    this.isAvailable = true,
    this.preparationTimeMinutes = 15,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercentage {
    if (!hasDiscount || originalPrice == 0) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).roundToDouble();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
      }
    }

    return ProductModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String?,
      images: parsedImages,
      status: json['status'] as String? ?? 'published',
      isFeatured: json['is_featured'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? (json['status'] == 'published'),
      preparationTimeMinutes: (json['preparation_time_minutes'] as num?)?.toInt() ?? 15,
      category: json['category'] != null ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  ProductModel copyWith({
    String? title,
    String? description,
    String? categoryId,
    double? price,
    double? originalPrice,
    int? stockQuantity,
    List<String>? images,
    String? status,
    bool? isFeatured,
    bool? isAvailable,
    int? preparationTimeMinutes,
    CategoryModel? category,
  }) {
    return ProductModel(
      id: id,
      shopId: shopId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      slug: slug,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku,
      images: images ?? this.images,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'category_id': categoryId,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'stock_quantity': stockQuantity,
      'sku': sku,
      'images': images,
      'status': status,
      'is_featured': isFeatured,
      'is_available': isAvailable,
    };
  }
}
