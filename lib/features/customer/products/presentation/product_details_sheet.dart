import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class ProductDetailsSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  final ShopModel shop;

  const ProductDetailsSheet({
    super.key,
    required this.product,
    required this.shop,
  });

  static Future<void> show(BuildContext context, {required ProductModel product, required ShopModel shop}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailsSheet(product: product, shop: shop),
    );
  }

  @override
  ConsumerState<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends ConsumerState<ProductDetailsSheet> {
  int _quantity = 1;
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final totalPrice = product.price * _quantity;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Product Image
              if (product.mainImage.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    image: DecorationImage(
                      image: NetworkImage(product.mainImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: const Icon(Icons.fastfood_rounded, size: 54, color: AppColors.primary),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Shop Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category?.name ?? 'Main Dish',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              '${product.preparationTimeMinutes} min prep',
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title & Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.formatLKR(product.price),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),

                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4),
                      ),
                    ],

                    const Divider(height: 32),

                    // Special Instructions input
                    TextField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: 'Special Instructions (Optional)',
                        hintText: 'e.g. Less spicy, extra sauce, no onions',
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Quantity and Add to Cart Row
                    Row(
                      children: [
                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 20),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 20),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Add Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                final cartNotifier = ref.read(cartControllerProvider.notifier);
                                final result = cartNotifier.addToCart(
                                  product: product,
                                  shop: widget.shop,
                                  quantity: _quantity,
                                  specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
                                );

                                if (result == CartAddStatus.shopConflict) {
                                  _showShopConflictDialog(context, cartNotifier, product, widget.shop);
                                } else {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added $_quantity × ${product.title} to cart'),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(CurrencyFormatter.formatLKR(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShopConflictDialog(BuildContext context, CartController cartNotifier, ProductModel product, ShopModel shop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace Cart Items?'),
        content: Text(
          'Your cart contains items from another shop. Clear existing items and start a new order from "${shop.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              cartNotifier.clearAndAddToCart(
                product: product,
                shop: shop,
                quantity: _quantity,
                specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
              );
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart reset with ${product.title} from ${shop.name}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }
}
