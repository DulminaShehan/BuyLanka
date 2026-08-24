import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/seller/dashboard/presentation/seller_dashboard_screen.dart';
import 'package:buylanka/features/seller/orders/controllers/orders_controller.dart';
import 'package:buylanka/features/seller/orders/presentation/orders_list_screen.dart';
import 'package:buylanka/features/seller/products/presentation/product_list_screen.dart';
import 'package:buylanka/features/seller/profile/presentation/seller_profile_screen.dart';

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

class SellerMainNavScreen extends ConsumerWidget {
  const SellerMainNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final ordersState = ref.watch(ordersControllerProvider);
    final pendingCount = ordersState.newOrders.length;

    final screens = [
      const SellerDashboardScreen(),
      const OrdersListScreen(),
      const ProductListScreen(),
      const SellerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(selectedNavIndexProvider.notifier).state = index,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text(
                  '$pendingCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text(
                  '$pendingCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Shop',
            ),
          ],
        ),
      ),
    );
  }
}
