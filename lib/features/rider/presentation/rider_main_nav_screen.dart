import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/rider/dashboard/presentation/rider_dashboard_screen.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/features/rider/deliveries/presentation/deliveries_list_screen.dart';
import 'package:buylanka/features/rider/earnings/presentation/rider_earnings_screen.dart';
import 'package:buylanka/features/rider/profile/presentation/rider_profile_screen.dart';

class RiderMainNavScreen extends ConsumerStatefulWidget {
  const RiderMainNavScreen({super.key});

  @override
  ConsumerState<RiderMainNavScreen> createState() => _RiderMainNavScreenState();
}

class _RiderMainNavScreenState extends ConsumerState<RiderMainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RiderDashboardScreen(),
    DeliveriesListScreen(),
    RiderEarningsScreen(),
    RiderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final deliveriesState = ref.watch(deliveriesControllerProvider);
    final activeCount = deliveriesState.activeDeliveries.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          elevation: 0,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: activeCount > 0,
                label: Text(activeCount.toString()),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.two_wheeler_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: activeCount > 0,
                label: Text(activeCount.toString()),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
              ),
              label: 'Deliveries',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              label: 'Earnings',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
