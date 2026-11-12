class PromotionModel {
  final String id;
  final String title;
  final String description;
  final String buttonText;
  final String? imageUrl;
  final String? code;
  final double? discountPercentage;
  final String? targetShopId;
  final String? targetCategoryId;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    this.buttonText = 'Order Now',
    this.imageUrl,
    this.code,
    this.discountPercentage,
    this.targetShopId,
    this.targetCategoryId,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      buttonText: json['button_text'] as String? ?? 'Order Now',
      imageUrl: json['image_url'] as String?,
      code: json['code'] as String?,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      targetShopId: json['target_shop_id'] as String?,
      targetCategoryId: json['target_category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'button_text': buttonText,
      'image_url': imageUrl,
      'code': code,
      'discount_percentage': discountPercentage,
      'target_shop_id': targetShopId,
      'target_category_id': targetCategoryId,
    };
  }
}

