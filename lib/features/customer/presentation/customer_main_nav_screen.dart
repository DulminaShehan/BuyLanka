import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/customer/favorites/presentation/favorites_screen.dart';
import 'package:buylanka/features/customer/home/presentation/customer_home_screen.dart';
import 'package:buylanka/features/customer/orders/controllers/customer_orders_controller.dart';
import 'package:buylanka/features/customer/orders/presentation/customer_orders_screen.dart';
import 'package:buylanka/features/customer/profile/presentation/customer_profile_screen.dart';
import 'package:buylanka/features/customer/search/presentation/customer_search_screen.dart';

class CustomerMainNavScreen extends ConsumerStatefulWidget {
  const CustomerMainNavScreen({super.key});

  @override
  ConsumerState<CustomerMainNavScreen> createState() => _CustomerMainNavScreenState();
}

class _CustomerMainNavScreenState extends ConsumerState<CustomerMainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CustomerHomeScreen(),
    CustomerSearchScreen(),
    CustomerOrdersScreen(),
    FavoritesScreen(),
    CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(customerOrdersControllerProvider);
    final activeOrdersCount = ordersState.activeOrders.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: activeOrdersCount > 0,
                label: Text('$activeOrdersCount'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: activeOrdersCount > 0,
                label: Text('$activeOrdersCount'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
