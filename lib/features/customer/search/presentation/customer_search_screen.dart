import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/features/customer/cart/presentation/cart_screen.dart';
import 'package:buylanka/features/customer/search/controllers/customer_search_controller.dart';
import 'package:buylanka/features/customer/shops/presentation/shop_details_screen.dart';
import 'package:buylanka/models/cart_item_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';

class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final _searchController = TextEditingController();

  final List<String> _popularSuggestions = [
    'Chicken Kottu',
    'Rice & Curry',
    'Burger',
    'Pizza',
    'Cheese Kottu',
    'Fried Rice',
    'Short Eats',
    'Iced Coffee',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerSearchControllerProvider);
    final controller = ref.read(customerSearchControllerProvider.notifier);
    final cartState = ref.watch(cartControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Food & Places', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Input Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search for "Kottu", "Burger", "Pizza"...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              controller.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    controller.search(val);
                  },
                ),
              ),

              Expanded(
                child: state.isSearching
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : state.query.isEmpty
                        ? _buildSuggestions(controller)
                        : !state.hasResults
                            ? _buildNoResults()
                            : _buildSearchResults(state),
              ),
            ],
          ),

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

  Widget _buildSuggestions(CustomerSearchController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches 🇱🇰',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
                labelStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                onPressed: () {
                  _searchController.text = suggestion;
                  controller.search(suggestion);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No results found for "${_searchController.text}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Try searching for another dish or restaurant.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(CustomerSearchState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        if (state.matchingShops.isNotEmpty) ...[
          const Text('Restaurants', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ...state.matchingShops.map((shop) => _buildShopCard(shop)),
          const SizedBox(height: 20),
        ],
        if (state.matchingProducts.isNotEmpty) ...[
          const Text('Dishes & Food Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ...state.matchingProducts.map((prod) => _buildProductCard(prod)),
        ],
      ],
    );
  }

  Widget _buildShopCard(ShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: shop.id)),
          );
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
        ),
        title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(shop.address ?? shop.city ?? 'Sri Lanka', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(shop.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () {
          // Open shop
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: product.shopId)),
          );
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            image: product.mainImage.isNotEmpty
                ? DecorationImage(image: NetworkImage(product.mainImage), fit: BoxFit.cover)
                : null,
          ),
          child: product.mainImage.isEmpty ? const Icon(Icons.fastfood_rounded, color: AppColors.primary) : null,
        ),
        title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(CurrencyFormatter.formatLKR(product.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
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
