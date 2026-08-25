import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/features/customer/cart/presentation/cart_screen.dart';
import 'package:buylanka/features/customer/products/presentation/product_details_sheet.dart';
import 'package:buylanka/features/customer/shops/controllers/shop_details_controller.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class ShopDetailsScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailsScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopDetailsControllerProvider(shopId));
    final controller = ref.read(shopDetailsControllerProvider(shopId).notifier);
    final cartState = ref.watch(cartControllerProvider);

    if (state.isLoading && state.shop == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final shop = state.shop;
    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: const Center(child: Text('Restaurant details not found')),
      );
    }

    final filteredProducts = state.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sliver AppBar with Hero Cover Image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty
                      ? Image.network(shop.bannerUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary,
                          child: const Center(
                            child: Icon(Icons.storefront_rounded, size: 64, color: Colors.white70),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      state.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: state.isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () => controller.toggleFavorite(),
                  ),
                ],
              ),

              // 2. Shop Info Header
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: shop.isOpen ? AppColors.success.withValues(alpha: 0.12) : AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              shop.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: shop.isOpen ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (shop.description != null && shop.description!.isNotEmpty)
                        Text(shop.description!, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text('(${shop.totalReviews} reviews)', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          const Text('25-35 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 16),
                          const Icon(Icons.pin_drop_outlined, color: AppColors.textLight, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.address ?? shop.city ?? 'Sri Lanka',
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Category Filter Chips Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeaderDelegate(
                  categories: state.availableCategories,
                  selectedCategory: state.selectedCategory ?? 'All',
                  onSelect: (cat) => controller.selectCategory(cat),
                ),
              ),

              // 4. Products Grid/List
              if (filteredProducts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.textLight),
                        SizedBox(height: 10),
                        Text('No menu items available in this category', style: TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductListItem(context, product, shop);
                      },
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),
            ],
          ),

          // 5. Floating Bottom Cart Bar (if active cart from this or any shop)
          if (cartState.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildFloatingCartPill(context, cartState),
            ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, ProductModel product, ShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => ProductDetailsSheet.show(context, product: product, shop: shop),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.formatLKR(product.price),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.formatLKR(product.originalPrice!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Product photo & Add Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      image: product.mainImage.isNotEmpty
                          ? DecorationImage(image: NetworkImage(product.mainImage), fit: BoxFit.cover)
                          : null,
                    ),
                    child: product.mainImage.isEmpty
                        ? const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 32)
                        : null,
                  ),
                  Positioned(
                    bottom: -8,
                    right: -8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const IconButton(
                        icon: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: null, // Tap is handled by the whole card
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCartPill(BuildContext context, CartStateModel cartState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cartState.totalItemCount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'View Cart',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatLKR(cartState.totalAmount),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelect;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 52;
  @override
  double get minExtent => 52;
  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory || oldDelegate.categories != categories;
  }
}
