import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/features/seller/orders/controllers/orders_controller.dart';
import 'package:buylanka/features/seller/orders/presentation/order_details_screen.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersControllerProvider);
    final activeTab = ordersState.activeTab;
    final currentOrders = ordersState.currentTabOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Order Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(ordersControllerProvider.notifier).loadOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Status Tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabPill(
                    ref,
                    tab: OrderTab.newOrders,
                    label: 'New Orders',
                    count: ordersState.newOrders.length,
                    isActive: activeTab == OrderTab.newOrders,
                    activeColor: AppColors.statusPending,
                  ),
                  const SizedBox(width: 8),
                  _buildTabPill(
                    ref,
                    tab: OrderTab.preparing,
                    label: 'Preparing',
                    count: ordersState.preparingOrders.length,
                    isActive: activeTab == OrderTab.preparing,
                    activeColor: AppColors.statusPreparing,
                  ),
                  const SizedBox(width: 8),
                  _buildTabPill(
                    ref,
                    tab: OrderTab.readyForPickup,
                    label: 'Ready for Pickup',
                    count: ordersState.readyOrders.length,
                    isActive: activeTab == OrderTab.readyForPickup,
                    activeColor: AppColors.statusReady,
                  ),
                  const SizedBox(width: 8),
                  _buildTabPill(
                    ref,
                    tab: OrderTab.history,
                    label: 'History',
                    count: ordersState.historyOrders.length,
                    isActive: activeTab == OrderTab.history,
                    activeColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentOrders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${activeTab == OrderTab.newOrders ? "New" : activeTab == OrderTab.preparing ? "Preparing" : activeTab == OrderTab.readyForPickup ? "Ready" : "Past"} Orders',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Orders in this status category will automatically update live.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(ordersControllerProvider.notifier).loadOrders(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: currentOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = currentOrders[index];
                            return _buildOrderCard(context, ref, order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(
    WidgetRef ref, {
    required OrderTab tab,
    required String label,
    required int count,
    required bool isActive,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: () => ref.read(ordersControllerProvider.notifier).setTab(tab),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Order Number & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    DateFormatter.formatRelative(order.createdAt),
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer & Delivery Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(
                          order.deliveryAddressText,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items Summary
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.productTitle,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
                      const Divider(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Note: "${order.customerNotes}"',
                              style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Total & Status Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Bill', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        CurrencyFormatter.format(order.totalAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),

                  // Action Buttons based on status
                  Row(
                    children: [
                      if (order.orderStatus == 'pending') ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => ref.read(ordersControllerProvider.notifier).rejectOrder(order.id),
                          child: const Text('Reject', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => ref.read(ordersControllerProvider.notifier).acceptOrder(order.id),
                          child: const Text('Accept', style: TextStyle(fontSize: 12)),
                        ),
                      ] else if (order.orderStatus == 'accepted' || order.orderStatus == 'preparing') ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Mark Ready', style: TextStyle(fontSize: 12)),
                          onPressed: () => ref.read(ordersControllerProvider.notifier).markReadyForPickup(order.id),
                        ),
                      ] else if (order.orderStatus == 'ready_for_pickup') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Awaiting Rider',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
