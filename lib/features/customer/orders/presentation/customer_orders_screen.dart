import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/customer/orders/controllers/customer_orders_controller.dart';
import 'package:buylanka/features/customer/orders/presentation/customer_order_details_screen.dart';
import 'package:buylanka/features/customer/tracking/presentation/live_order_tracking_screen.dart';
import 'package:buylanka/models/order_model.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> with SingleTickerProviderStateMixin {
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
    final state = ref.watch(customerOrdersControllerProvider);
    final controller = ref.read(customerOrdersControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Active (${state.activeOrders.length})'),
            Tab(text: 'History (${state.completedOrders.length + state.cancelledOrders.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => controller.loadOrders(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(context, state.activeOrders, isActive: true),
                  _buildOrdersList(context, [...state.completedOrders, ...state.cancelledOrders], isActive: false),
                ],
              ),
            ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<OrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.moped_rounded : Icons.receipt_long_outlined,
              size: 54,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'No active orders' : 'No order history yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Your active food deliveries will appear here.' : 'Orders you place will be recorded here.',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        final shop = order.shop;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerOrderDetailsScreen(orderId: order.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant and Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop?.name ?? 'Restaurant',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (order.createdAt != null)
                                Text(
                                  DateFormatter.formatDateTime(order.createdAt!),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                ),
                            ],
                          ),
                        ],
                      ),
                      _buildStatusPill(order.orderStatus),
                    ],
                  ),

                  const Divider(height: 20),

                  // Order items brief
                  Text(
                    order.items.isNotEmpty
                        ? order.items.map((i) => '${i.quantity}x ${i.productTitle}').join(', ')
                        : 'Order #${order.orderNumber}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),

                  const SizedBox(height: 12),

                  // Total and Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.formatLKR(order.totalAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (isActive)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LiveOrderTrackingScreen(orderId: order.id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.near_me_rounded, size: 16),
                          label: const Text('Track Live', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      else
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerOrderDetailsScreen(orderId: order.id),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    Color bg;
    String label = status.replaceAll('_', ' ').toUpperCase();

    switch (status.toLowerCase()) {
      case 'delivered':
        color = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.12);
        break;
      case 'cancelled':
      case 'rejected':
        color = AppColors.error;
        bg = AppColors.errorBg;
        break;
      case 'preparing':
      case 'accepted':
        color = AppColors.warning;
        bg = AppColors.warning.withValues(alpha: 0.12);
        break;
      default:
        color = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
