import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/addresses/controllers/address_controller.dart';
import 'package:buylanka/features/customer/addresses/presentation/saved_addresses_screen.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/features/customer/cart/presentation/cart_screen.dart';
import 'package:buylanka/features/customer/favorites/controllers/favorites_controller.dart';
import 'package:buylanka/features/customer/home/controllers/customer_home_controller.dart';
import 'package:buylanka/features/customer/notifications/controllers/notifications_controller.dart';
import 'package:buylanka/features/customer/notifications/presentation/notifications_screen.dart';
import 'package:buylanka/features/customer/products/presentation/product_details_sheet.dart';
import 'package:buylanka/features/customer/profile/presentation/customer_profile_screen.dart';
import 'package:buylanka/features/customer/search/presentation/customer_search_screen.dart';
import 'package:buylanka/features/customer/shops/presentation/shop_details_screen.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/promotion_model.dart';
import 'package:buylanka/models/shop_model.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  // Built-in food categories matching Uber Eats / BuyLanka design requirements
  static const List<Map<String, dynamic>> _coreFoodCategories = [
    {
      'id': 'cat_burgers',
      'name': 'Burgers',
      'slug': 'burgers',
      'icon': Icons.lunch_dining_rounded,
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'cat_pizza',
      'name': 'Pizza',
      'slug': 'pizza',
      'icon': Icons.local_pizza_rounded,
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'cat_rice',
      'name': 'Rice',
      'slug': 'rice',
      'icon': Icons.rice_bowl_rounded,
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'cat_kottu',
      'name': 'Kottu',
      'slug': 'kottu',
      'icon': Icons.ramen_dining_rounded,
      'image': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'cat_drinks',
      'name': 'Drinks',
      'slug': 'drinks',
      'icon': Icons.local_cafe_rounded,
      'image': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'cat_desserts',
      'name': 'Desserts',
      'slug': 'desserts',
      'icon': Icons.cake_rounded,
      'image': 'https://images.unsplash.com/photo-1587314168485-3236d6710814?auto=format&fit=crop&w=300&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(customerHomeControllerProvider);
    final homeController = ref.read(customerHomeControllerProvider.notifier);
    final addressState = ref.watch(addressControllerProvider);
    final notifState = ref.watch(notificationsControllerProvider);
    final cartState = ref.watch(cartControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final favState = ref.watch(favoritesControllerProvider);

    final selectedAddress = addressState.selectedAddress?.fullAddressText ?? homeState.currentDeliveryAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await homeController.loadHomeData();
                await ref.read(favoritesControllerProvider.notifier).loadFavorites();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Home Screen Header & Delivery Location
                  SliverToBoxAdapter(
                    child: _buildHeaderSection(
                      context: context,
                      selectedAddress: selectedAddress,
                      unreadNotifs: notifState.unreadCount,
                      profileAvatar: authState.profile?.avatarUrl,
                    ),
                  ),

                  // 2. Modern Search Bar with Filter
                  SliverToBoxAdapter(
                    child: _buildSearchBar(context),
                  ),

                  // Error Banner with Retry (if any)
                  if (homeState.errorMessage != null && !homeState.isLoading)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                homeState.errorMessage!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.error,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => homeController.loadHomeData(),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Promotional Banners Section
                  SliverToBoxAdapter(
                    child: _buildPromotionalBanners(context, homeState.promotions),
                  ),

                  // 4. Food Categories Section
                  SliverToBoxAdapter(
                    child: _buildCategoriesSection(
                      context: context,
                      homeState: homeState,
                      controller: homeController,
                    ),
                  ),

                  // 5. Popular Restaurants Section ⭐
                  SliverToBoxAdapter(
                    child: _buildPopularRestaurantsSection(
                      context: context,
                      shops: homeState.popularShops,
                      favShops: favState.favoriteShops,
                    ),
                  ),

                  // 6. Recommended For You Section 🇱🇰
                  SliverToBoxAdapter(
                    child: _buildRecommendedSection(
                      context: context,
                      products: homeState.featuredProducts,
                      shops: homeState.nearbyShops,
                      favProducts: favState.favoriteProducts,
                      isLoading: homeState.isLoading,
                    ),
                  ),

                  // 7. Nearby & All Restaurants Feed
                  SliverToBoxAdapter(
                    child: _buildNearbyRestaurantsHeader(homeState),
                  ),

                  if (homeState.isLoading && homeState.nearbyShops.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text(
                                'Discovering great food nearby...',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (homeState.nearbyShops.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyFeedState(context, homeController),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final shop = homeState.nearbyShops[index];
                            final isFav = favState.favoriteShops.any((s) => s.id == shop.id);
                            return _buildRestaurantFeedCard(context, shop, isFav);
                          },
                          childCount: homeState.nearbyShops.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating View Cart Pill (when items exist in cart)
            if (cartState.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _buildFloatingCartPill(context, cartState),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. BRANDED HEADER & DELIVERY LOCATION BAR
  // ===========================================================================
  Widget _buildHeaderSection({
    required BuildContext context,
    required String selectedAddress,
    required int unreadNotifs,
    String? profileAvatar,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: BuyLanka Logo + Notifications + Customer Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Branded BuyLanka Logo & Identity
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BuyLanka',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Food & Grocery Delivery',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Actions: Notifications & Profile Icon
              Row(
                children: [
                  // Notifications with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                      ),
                      if (unreadNotifs > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Customer Profile Avatar / Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                        image: profileAvatar != null && profileAvatar.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profileAvatar),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profileAvatar == null || profileAvatar.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Delivery Location Bar (Deliver to: Colombo 05, Western Province)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELIVER TO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          selectedAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MODERN SEARCH BAR WITH FILTER
  // ===========================================================================
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search for food, Kottu, Burger, Rice...',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. PROMOTIONAL BANNERS CAROUSEL
  // ===========================================================================
  Widget _buildPromotionalBanners(BuildContext context, List<PromotionModel> promotions) {
    if (promotions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: promotions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return _buildPromoCard(context, promo, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, PromotionModel promo, int index) {
    // Elegant color gradients for banners
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF00838F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF283593)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    final gradient = gradients[index % gradients.length];

    return Container(
      width: 310,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background food image on the right with fade overlay
            if (promo.imageUrl != null && promo.imageUrl!.isNotEmpty)
              Positioned(
                right: -20,
                top: -10,
                bottom: -10,
                width: 170,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.45],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: CachedNetworkImage(
                    imageUrl: promo.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white12),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Content text & button
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 170,
                        child: Text(
                          promo.description,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // "Order Now" action button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            promo.buttonText,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primaryDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. FOOD CATEGORIES SECTION
  // ===========================================================================
  Widget _buildCategoriesSection({
    required BuildContext context,
    required CustomerHomeState homeState,
    required CustomerHomeController controller,
  }) {
    // Merge Supabase categories with our core 6 food categories if empty
    final List<Map<String, dynamic>> displayCategories = [];

    if (homeState.categories.isNotEmpty) {
      for (final cat in homeState.categories) {
        displayCategories.add({
          'id': cat.id,
          'name': cat.name,
          'slug': cat.slug,
          'icon': _getCategoryIcon(cat.name),
          'image': cat.imageUrl,
          'model': cat,
        });
      }
    } else {
      displayCategories.addAll(_coreFoodCategories);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  _showAllCategoriesSheet(context, displayCategories, controller, homeState.selectedCategory);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category Items
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = displayCategories[index];
              final categoryName = cat['name'] as String;
              final isSelected = homeState.selectedCategory?.name == categoryName;
              final iconData = (cat['icon'] as IconData?) ?? Icons.fastfood_rounded;

              return InkWell(
                onTap: () {
                  final catModel = cat['model'] as CategoryModel? ??
                      CategoryModel(
                        id: cat['id'] as String,
                        name: categoryName,
                        slug: cat['slug'] as String,
                      );
                  controller.selectCategory(catModel);
                },
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categoryName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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

  void _showAllCategoriesSheet(
    BuildContext context,
    List<Map<String, dynamic>> categories,
    CustomerHomeController controller,
    CategoryModel? selectedCategory,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'All Food Categories',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final name = cat['name'] as String;
                final isSelected = selectedCategory?.name == name;
                final icon = (cat['icon'] as IconData?) ?? Icons.fastfood_rounded;

                return InkWell(
                  onTap: () {
                    final catModel = cat['model'] as CategoryModel? ??
                        CategoryModel(
                          id: cat['id'] as String,
                          name: name,
                          slug: cat['slug'] as String,
                        );
                    controller.selectCategory(catModel);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: AppColors.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. POPULAR RESTAURANTS SECTION ⭐
  // ===========================================================================
  Widget _buildPopularRestaurantsSection({
    required BuildContext context,
    required List<ShopModel> shops,
    required List<ShopModel> favShops,
  }) {
    // If Supabase has zero shops in dev seed, provide fallback preview restaurants
    final displayShops = shops.isNotEmpty
        ? shops
        : const [
            ShopModel(
              id: 'preview_niyabadawa',
              sellerId: 'seller_1',
              name: 'Niyabadawa',
              slug: 'niyabadawa',
              bannerUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=500&q=80',
              logoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=150&q=80',
              status: 'approved',
              rating: 4.8,
              totalReviews: 1200,
            ),
            ShopModel(
              id: 'preview_smarthub',
              sellerId: 'seller_2',
              name: 'SmartHub',
              slug: 'smarthub',
              bannerUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=500&q=80',
              logoUrl: 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=150&q=80',
              status: 'approved',
              rating: 4.6,
              totalReviews: 856,
            ),
            ShopModel(
              id: 'preview_ceylon_pot',
              sellerId: 'seller_3',
              name: 'Ceylon Clay Pot',
              slug: 'ceylon-clay-pot',
              bannerUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=500&q=80',
              status: 'approved',
              rating: 4.9,
              totalReviews: 2100,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Restaurants ⭐',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Restaurant Cards
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayShops.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final shop = displayShops[index];
              final isFav = favShops.any((s) => s.id == shop.id);
              return _buildPopularRestaurantCard(context, shop, isFav, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularRestaurantCard(BuildContext context, ShopModel shop, bool isFav, int index) {
    // Delivery time calculations
    final deliveryTimes = ['20–30 min', '25–35 min', '15–25 min', '30–40 min'];
    final deliveryTime = deliveryTimes[index % deliveryTimes.length];

    return Container(
      width: 265,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
              // Cover Image & Overlaid Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: SizedBox(
                      height: 125,
                      width: double.infinity,
                      child: shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: shop.bannerUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 36),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 36),
                            ),
                    ),
                  ),

                  // Favorite Heart Button (Top-Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesControllerProvider.notifier).toggleShopFavorite(shop.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.danger : AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Shop Logo / Avatar Badge (Bottom-Left overlay)
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: ClipOval(
                        child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: shop.logoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(Icons.storefront_rounded, size: 20),
                                errorWidget: (context, url, error) => const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                              )
                            : const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),

              // Restaurant Info & Details
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '(${_formatReviewCount(shop.totalReviews)})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.two_wheeler_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          deliveryTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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

  // ===========================================================================
  // 6. RECOMMENDED FOR YOU SECTION 🇱🇰
  // ===========================================================================
  Widget _buildRecommendedSection({
    required BuildContext context,
    required List<ProductModel> products,
    required List<ShopModel> shops,
    required List<ProductModel> favProducts,
    required bool isLoading,
  }) {
    // If products are empty in dev/seed, provide high-quality fallback food products
    final displayProducts = products.isNotEmpty
        ? products
        : const [
            ProductModel(
              id: 'rec_chicken_kottu',
              shopId: 'preview_niyabadawa',
              title: 'Crispy Roast Chicken Cheese Kottu',
              slug: 'chicken-cheese-kottu',
              price: 1350,
              originalPrice: 1500,
              images: ['https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80'],
            ),
            ProductModel(
              id: 'rec_burger',
              shopId: 'preview_smarthub',
              title: 'Double Beef Bacon Burger',
              slug: 'double-beef-burger',
              price: 1650,
              originalPrice: 1950,
              images: ['https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80'],
            ),
            ProductModel(
              id: 'rec_lamprais',
              shopId: 'preview_ceylon_pot',
              title: 'Authentic Banana Leaf Lamprais',
              slug: 'banana-leaf-lamprais',
              price: 1450,
              images: ['https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80'],
            ),
            ProductModel(
              id: 'rec_pizza',
              shopId: 'preview_smarthub',
              title: 'Woodfired Hot Butter Cuttlefish Pizza',
              slug: 'hbc-pizza',
              price: 2100,
              images: ['https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80'],
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You 🇱🇰',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Product List
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = displayProducts[index];
              final isFav = favProducts.any((p) => p.id == product.id);
              final shop = _resolveShopForProduct(product.shopId, shops);

              return _buildRecommendedFoodCard(context, product, shop, isFav);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedFoodCard(
    BuildContext context,
    ProductModel product,
    ShopModel shop,
    bool isFav,
  ) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ProductDetailsSheet.show(context, product: product, shop: shop),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image with Favorite & Discount Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: product.mainImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.mainImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 32),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 32),
                            ),
                    ),
                  ),

                  // Favorite Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesControllerProvider.notifier).toggleProductFavorite(product.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.danger : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge (if any)
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercentage.toInt()}% OFF',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info: Title, Shop, Price
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatLKR(product.price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
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

  // ===========================================================================
  // 7. NEARBY RESTAURANTS FEED HEADER & CARDS
  // ===========================================================================
  Widget _buildNearbyRestaurantsHeader(CustomerHomeState homeState) {
    final title = homeState.selectedCategory != null
        ? '${homeState.selectedCategory!.name} Spots & Dishes'
        : 'Nearby Restaurants & Food Stalls 🛵';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (homeState.selectedCategory != null)
            GestureDetector(
              onTap: () {
                ref.read(customerHomeControllerProvider.notifier).selectCategory(null);
              },
              child: Text(
                'Clear Filter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantFeedCard(BuildContext context, ShopModel shop, bool isFav) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
              // Banner
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: shop.bannerUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesControllerProvider.notifier).toggleShopFavorite(shop.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.danger : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                shop.rating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${_formatReviewCount(shop.totalReviews)})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                              const SizedBox(width: 8),
                              const Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '20–30 min',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OPEN',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  Widget _buildEmptyFeedState(BuildContext context, CustomerHomeController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No restaurants found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing your category filter or pull down to refresh the feed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.loadHomeData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refresh Feed'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. FLOATING VIEW CART PILL
  // ===========================================================================
  Widget _buildFloatingCartPill(BuildContext context, CartStateModel cartState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
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
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cartState.totalItemCount}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'View Cart',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatLKR(cartState.totalAmount),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  static String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  static IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('rice') || lower.contains('curry')) return Icons.rice_bowl_rounded;
    if (lower.contains('kottu')) return Icons.ramen_dining_rounded;
    if (lower.contains('drink') || lower.contains('beverage') || lower.contains('tea') || lower.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('dessert') || lower.contains('cake') || lower.contains('ice')) {
      return Icons.cake_rounded;
    }
    return Icons.restaurant_rounded;
  }

  static ShopModel _resolveShopForProduct(String shopId, List<ShopModel> shops) {
    try {
      return shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return ShopModel(
        id: shopId,
        sellerId: '',
        name: 'BuyLanka Partner Spot',
        slug: 'buylanka-spot',
        status: 'approved',
        rating: 4.8,
        totalReviews: 120,
      );
    }
  }
}
