import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/favorites/controllers/favorites_controller.dart';
import 'package:buylanka/features/customer/shops/presentation/shop_details_screen.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesControllerProvider);
    final controller = ref.read(favoritesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Shops (${state.favoriteShops.length})'),
            Tab(text: 'Dishes (${state.favoriteProducts.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => controller.loadFavorites(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShopsTab(state.favoriteShops, controller),
                  _buildProductsTab(state.favoriteProducts, controller),
                ],
              ),
            ),
    );
  }

  Widget _buildShopsTab(List<ShopModel> shops, FavoritesController controller) {
    if (shops.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 54, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No favorite restaurants yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Tap the heart icon on any restaurant to save it here.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final shop = shops[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: shop.id)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      image: shop.bannerUrl != null
                          ? DecorationImage(image: NetworkImage(shop.bannerUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: shop.bannerUrl == null
                        ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(shop.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Text('25-35 min', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                    onPressed: () => controller.toggleShopFavorite(shop.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(List<ProductModel> products, FavoritesController controller) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded, size: 54, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No favorite dishes yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Save your favorite Sri Lankan meals for quick ordering.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    image: product.mainImage.isNotEmpty
                        ? DecorationImage(image: NetworkImage(product.mainImage), fit: BoxFit.cover)
                        : null,
                  ),
                  child: product.mainImage.isEmpty
                      ? const Icon(Icons.fastfood_rounded, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatLKR(product.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                  onPressed: () => controller.toggleProductFavorite(product.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
