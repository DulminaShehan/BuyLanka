import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String? specialInstructions;

  const CartItemModel({
    required this.product,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get unitPrice => product.price;
  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'product_title': product.title,
      'unit_price': product.price,
      'quantity': quantity,
      'total_price': totalPrice,
      'special_instructions': specialInstructions,
    };
  }
}

class CartStateModel {
  final ShopModel? shop;
  final List<CartItemModel> items;

  const CartStateModel({
    this.shop,
    this.items = const [],
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get deliveryFee => isEmpty ? 0.0 : 250.0;
  double get discountAmount => 0.0;
  double get totalAmount => subtotal + deliveryFee - discountAmount;

  CartStateModel copyWith({
    ShopModel? shop,
    List<CartItemModel>? items,
    bool clearShop = false,
  }) {
    return CartStateModel(
      shop: clearShop ? null : (shop ?? this.shop),
      items: items ?? this.items,
    );
  }
}
