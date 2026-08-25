import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

enum CartAddStatus {
  success,
  shopConflict,
  productUnavailable,
}

class CartController extends StateNotifier<CartStateModel> {
  CartController() : super(const CartStateModel());

  /// Try adding a product to cart with single-restaurant enforcement
  CartAddStatus addToCart({
    required ProductModel product,
    required ShopModel shop,
    int quantity = 1,
    String? specialInstructions,
  }) {
    if (!product.isAvailable || product.status != 'published') {
      return CartAddStatus.productUnavailable;
    }

    // Check if cart has items from another shop
    if (state.isNotEmpty && state.shop != null && state.shop!.id != shop.id) {
      return CartAddStatus.shopConflict;
    }

    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    List<CartItemModel> updatedItems;

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final newQuantity = existing.quantity + quantity;
      updatedItems = List<CartItemModel>.from(state.items);
      updatedItems[existingIndex] = existing.copyWith(
        quantity: newQuantity,
        specialInstructions: specialInstructions ?? existing.specialInstructions,
      );
    } else {
      updatedItems = [
        ...state.items,
        CartItemModel(
          product: product,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      ];
    }

    state = state.copyWith(shop: shop, items: updatedItems);
    return CartAddStatus.success;
  }

  /// Force clear existing cart and add item from new shop
  void clearAndAddToCart({
    required ProductModel product,
    required ShopModel shop,
    int quantity = 1,
    String? specialInstructions,
  }) {
    state = CartStateModel(
      shop: shop,
      items: [
        CartItemModel(
          product: product,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      ],
    );
  }

  /// Update item quantity
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  /// Remove single item from cart
  void removeItem(String productId) {
    final updated = state.items.where((i) => i.product.id != productId).toList();
    if (updated.isEmpty) {
      state = const CartStateModel();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  /// Clear entire cart
  void clearCart() {
    state = const CartStateModel();
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, CartStateModel>((ref) {
  return CartController();
});
