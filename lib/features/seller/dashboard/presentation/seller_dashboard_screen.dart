import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/seller/dashboard/controllers/dashboard_controller.dart';
import 'package:buylanka/features/seller/orders/controllers/orders_controller.dart';
import 'package:buylanka/features/seller/orders/presentation/order_details_screen.dart';
import 'package:buylanka/features/seller/presentation/seller_main_nav_screen.dart';
import 'package:buylanka/features/seller/products/presentation/add_edit_product_screen.dart';
import 'package:buylanka/features/seller/shop/controllers/shop_controller.dart';
import 'package:buylanka/features/seller/shop/presentation/shop_settings_screen.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopControllerProvider);
    final metrics = ref.watch(dashboardMetricsProvider);
    final ordersState = ref.watch(ordersControllerProvider);
    final shop = shopState.shop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          tooltip: 'Exit Partner Portal',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Exit Seller Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: const Text(
                  'Do you want to sign out from your restaurant dashboard and return to the main customer app?',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Exit & Sign Out'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(authControllerProvider.notifier).signOut();
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop?.name ?? 'My Restaurant',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    shop?.city ?? 'Partner Portal',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Open / Closed Switch
          if (shop != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shop.isOpen ? AppColors.successBg : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: shop.isOpen ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3.5,
                          backgroundColor: shop.isOpen ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          shop.isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: shop.isOpen ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch.adaptive(
                    value: shop.isOpen,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) {
                      ref.read(shopControllerProvider.notifier).toggleOpenStatus(val);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(shopControllerProvider.notifier).loadShop();
          await ref.read(ordersControllerProvider.notifier).loadOrders();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Sales Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Sales",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatDate(DateTime.now()),
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      CurrencyFormatter.format(metrics.todayRevenue),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSalesStat('Orders', '${metrics.todayOrdersCount}'),
                        _buildSalesStat('Completed', '${metrics.completedOrdersCount}'),
                        _buildSalesStat('Commission', '${shop?.rating.toStringAsFixed(1) ?? "5.0"} ★'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Order Status Pillars
              const Text(
                'Live Order Queue',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQueueCard(
                      title: 'Pending',
                      count: metrics.pendingOrdersCount,
                      color: AppColors.statusPending,
                      bgColor: AppColors.warningBg,
                      icon: Icons.hourglass_top_rounded,
                      onTap: () {
                        ref.read(ordersControllerProvider.notifier).setTab(OrderTab.newOrders);
                        ref.read(selectedNavIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQueueCard(
                      title: 'Preparing',
                      count: metrics.preparingOrdersCount,
                      color: AppColors.statusPreparing,
                      bgColor: const Color(0xFFF3E8FF),
                      icon: Icons.soup_kitchen_rounded,
                      onTap: () {
                        ref.read(ordersControllerProvider.notifier).setTab(OrderTab.preparing);
                        ref.read(selectedNavIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQueueCard(
                      title: 'Ready',
                      count: metrics.readyOrdersCount,
                      color: AppColors.statusReady,
                      bgColor: AppColors.successBg,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () {
                        ref.read(ordersControllerProvider.notifier).setTab(OrderTab.readyForPickup);
                        ref.read(selectedNavIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add Food Item',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Manage Menu',
                      color: AppColors.secondary,
                      onTap: () {
                        ref.read(selectedNavIndexProvider.notifier).state = 2;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.store_rounded,
                      label: 'Shop Settings',
                      color: AppColors.info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopSettingsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Active Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => ref.read(selectedNavIndexProvider.notifier).state = 1,
                    child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (ordersState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (ordersState.newOrders.isEmpty && ordersState.preparingOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      const Text(
                        'No Active Orders Right Now',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New incoming orders from customers will appear here automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: [...ordersState.newOrders, ...ordersState.preparingOrders].take(4).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = [...ordersState.newOrders, ...ordersState.preparingOrders][index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              _buildStatusBadge(order.orderStatus),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${order.customerName} • ${order.totalItemCount} items',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CurrencyFormatter.format(order.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              Text(
                                DateFormatter.formatRelative(order.createdAt),
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Details', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (order.orderStatus == 'pending')
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ref.read(ordersControllerProvider.notifier).acceptOrder(order.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                      backgroundColor: AppColors.success,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                  ),
                                )
                              else if (order.orderStatus == 'accepted' || order.orderStatus == 'preparing')
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ref.read(ordersControllerProvider.notifier).markReadyForPickup(order.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                      backgroundColor: AppColors.primary,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text('Mark Ready', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildQueueCard({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'pending':
        bg = AppColors.warningBg;
        text = AppColors.statusPending;
        label = 'Pending';
        break;
      case 'accepted':
      case 'preparing':
        bg = const Color(0xFFF3E8FF);
        text = AppColors.statusPreparing;
        label = 'Preparing';
        break;
      case 'ready_for_pickup':
        bg = AppColors.successBg;
        text = AppColors.statusReady;
        label = 'Ready';
        break;
      default:
        bg = AppColors.surfaceVariant;
        text = AppColors.textSecondary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
