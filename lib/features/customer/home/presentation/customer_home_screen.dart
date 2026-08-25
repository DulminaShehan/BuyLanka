import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/addresses/controllers/address_controller.dart';
import 'package:buylanka/features/customer/addresses/presentation/saved_addresses_screen.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/features/customer/cart/presentation/cart_screen.dart';
import 'package:buylanka/features/customer/home/controllers/customer_home_controller.dart';
import 'package:buylanka/features/customer/notifications/controllers/notifications_controller.dart';
import 'package:buylanka/features/customer/notifications/presentation/notifications_screen.dart';
import 'package:buylanka/features/customer/products/presentation/product_details_sheet.dart';
import 'package:buylanka/features/customer/search/presentation/customer_search_screen.dart';
import 'package:buylanka/features/customer/shops/presentation/shop_details_screen.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(customerHomeControllerProvider);
    final homeController = ref.read(customerHomeControllerProvider.notifier);
    final addressState = ref.watch(addressControllerProvider);
    final notifState = ref.watch(notificationsControllerProvider);
    final cartState = ref.watch(cartControllerProvider);

    final selectedAddress = addressState.selectedAddress?.fullAddressText ?? homeState.currentDeliveryAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => homeController.loadHomeData(),
            child: CustomScrollView(
              slivers: [
                // 1. App Bar Header with Delivery Address & Notifications
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  snap: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('DELIVER TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 0.5)),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
                                child: Text(
                                  selectedAddress,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                        if (notifState.unreadCount > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // 2. Search Bar Trigger
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text(
                              'Search for food, Kottu, Burger, Rice...',
                              style: TextStyle(color: AppColors.textLight, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Promotional Banners
                SliverToBoxAdapter(
                  child: _buildPromoBanners(),
                ),

                // 4. Food / Shop Categories
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(homeState, homeController),
                ),

                // 5. Popular Restaurants Carousel
                SliverToBoxAdapter(
                  child: _buildPopularShopsSection(context, homeState.popularShops),
                ),

                // 6. Recommended Sri Lankan Dishes Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended For You 🇱🇰',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${homeState.featuredProducts.length} items',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                if (homeState.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                else if (homeState.featuredProducts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No featured dishes found.', style: TextStyle(color: AppColors.textLight)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.76,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = homeState.featuredProducts[index];
                          return _buildProductCard(context, product, homeState.nearbyShops);
                        },
                        childCount: homeState.featuredProducts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Floating Cart Bar (if items in cart)
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

  Widget _buildPromoBanners() {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPromoCard(
            title: 'Kottu Nights 🎉',
            subtitle: 'Get 20% OFF on all chicken & cheese kottu orders',
            gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9800)]),
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(width: 12),
          _buildPromoCard(
            title: 'Free Delivery 🛵',
            subtitle: 'On all orders above Rs. 2,500 this week',
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)]),
            icon: Icons.delivery_dining_rounded,
          ),
          const SizedBox(width: 12),
          _buildPromoCard(
            title: 'Authentic Taste 🇱🇰',
            subtitle: 'Fresh Ceylon spice curries delivered in 30 mins',
            gradient: const LinearGradient(colors: [Color(0xFF311B92), Color(0xFF673AB7)]),
            icon: Icons.restaurant_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required Gradient gradient,
    required IconData icon,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(CustomerHomeState homeState, CustomerHomeController controller) {
    final categories = homeState.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 90,
          child: categories.isEmpty
              ? _buildDefaultCategoryChips()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = homeState.selectedCategory?.id == cat.id;

                    return InkWell(
                      onTap: () => controller.selectCategory(cat),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(cat.name),
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDefaultCategoryChips() {
    final defaultCats = [
      {'name': 'Burgers', 'icon': Icons.lunch_dining_rounded},
      {'name': 'Pizza', 'icon': Icons.local_pizza_rounded},
      {'name': 'Rice', 'icon': Icons.rice_bowl_rounded},
      {'name': 'Kottu', 'icon': Icons.ramen_dining_rounded},
      {'name': 'Drinks', 'icon': Icons.local_cafe_rounded},
      {'name': 'Desserts', 'icon': Icons.cake_rounded},
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: defaultCats.length,
      separatorBuilder: (context, index) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final item = defaultCats[index];
        return Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(item['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('rice')) return Icons.rice_bowl_rounded;
    if (lower.contains('kottu')) return Icons.ramen_dining_rounded;
    if (lower.contains('drink') || lower.contains('beverage')) return Icons.local_cafe_rounded;
    if (lower.contains('cake') || lower.contains('dessert')) return Icons.cake_rounded;
    if (lower.contains('grocery')) return Icons.shopping_basket_rounded;
    return Icons.restaurant_rounded;
  }

  Widget _buildPopularShopsSection(BuildContext context, List<ShopModel> shops) {
    if (shops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Popular Restaurants ⭐',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shops.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: shop.id)),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 105,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          image: shop.bannerUrl != null
                              ? DecorationImage(image: NetworkImage(shop.bannerUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: shop.bannerUrl == null
                            ? const Center(child: Icon(Icons.storefront_rounded, size: 36, color: AppColors.primary))
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(shop.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 8),
                                const Text('• 25-35 min', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, List<ShopModel> shops) {
    ShopModel? shop;
    try {
      shop = shops.firstWhere((s) => s.id == product.shopId);
    } catch (_) {
      shop = ShopModel(
        id: product.shopId,
        sellerId: '',
        name: 'BuyLanka Restaurant',
        slug: '',
        status: 'approved',
        rating: 4.8,
        totalReviews: 50,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => ProductDetailsSheet.show(context, product: product, shop: shop!),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: product.mainImage.isNotEmpty
                    ? DecorationImage(image: NetworkImage(product.mainImage), fit: BoxFit.cover)
                    : null,
              ),
              child: product.mainImage.isEmpty
                  ? const Center(child: Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 36))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.name,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatLKR(product.price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
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
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
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
                    const Text('View Cart', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
