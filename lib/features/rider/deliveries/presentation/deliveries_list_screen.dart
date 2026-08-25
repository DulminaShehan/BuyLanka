import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/features/rider/deliveries/presentation/delivery_details_screen.dart';
import 'package:buylanka/features/rider/map/presentation/delivery_map_screen.dart';
import 'package:buylanka/models/delivery_model.dart';

enum HistoryTimeFilter { today, thisWeek, thisMonth, all }

class DeliveriesListScreen extends ConsumerStatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  ConsumerState<DeliveriesListScreen> createState() => _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends ConsumerState<DeliveriesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HistoryTimeFilter _selectedFilter = HistoryTimeFilter.today;

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
    final deliveriesState = ref.watch(deliveriesControllerProvider);
    final activeDeliveries = deliveriesState.activeDeliveries;
    final allHistory = deliveriesState.completedDeliveries;

    // Filter history based on selected chip
    final historyDeliveries = allHistory.where((d) {
      if (_selectedFilter == HistoryTimeFilter.all) return true;
      final date = d.deliveredAt ?? d.createdAt ?? DateTime.now();
      final now = DateTime.now();

      if (_selectedFilter == HistoryTimeFilter.today) {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_selectedFilter == HistoryTimeFilter.thisWeek) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek);
      } else if (_selectedFilter == HistoryTimeFilter.thisMonth) {
        return date.year == now.year && date.month == now.month;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Deliveries', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Active (${activeDeliveries.length})'),
            Tab(text: 'History (${allHistory.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Active Deliveries Tab
          _buildActiveDeliveriesTab(activeDeliveries),

          // 2. History Deliveries Tab
          _buildHistoryDeliveriesTab(historyDeliveries),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveriesTab(List<DeliveryModel> activeDeliveries) {
    if (activeDeliveries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.delivery_dining_outlined,
        title: 'No active deliveries',
        subtitle: 'New delivery assignments will appear here automatically in real time.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(deliveriesControllerProvider.notifier).loadDeliveries(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: activeDeliveries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final delivery = activeDeliveries[index];
          return _buildDeliveryCard(context, delivery, isActive: true);
        },
      ),
    );
  }

  Widget _buildHistoryDeliveriesTab(List<DeliveryModel> historyDeliveries) {
    return Column(
      children: [
        // Time filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Today', HistoryTimeFilter.today),
                const SizedBox(width: 8),
                _buildFilterChip('This Week', HistoryTimeFilter.thisWeek),
                const SizedBox(width: 8),
                _buildFilterChip('This Month', HistoryTimeFilter.thisMonth),
                const SizedBox(width: 8),
                _buildFilterChip('All Time', HistoryTimeFilter.all),
              ],
            ),
          ),
        ),

        Expanded(
          child: historyDeliveries.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No completed deliveries',
                  subtitle: 'Completed deliveries for the selected period will be listed here.',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(deliveriesControllerProvider.notifier).loadDeliveries(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: historyDeliveries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final delivery = historyDeliveries[index];
                      return _buildDeliveryCard(context, delivery, isActive: false);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, HistoryTimeFilter filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, DeliveryModel delivery, {required bool isActive}) {
    final orderNumber = delivery.order?.orderNumber ?? delivery.orderId.substring(0, 8).toUpperCase();
    final shopName = delivery.order?.shop?.name ?? 'Restaurant';
    final itemsCount = delivery.order?.items.length ?? 1;
    final totalAmount = delivery.order?.totalAmount ?? 0.0;
    final fee = delivery.order?.deliveryFee ?? 350.0;
    final dateStr = delivery.deliveredAt != null
        ? DateFormatter.formatDateTime(delivery.deliveredAt!)
        : (delivery.createdAt != null ? DateFormatter.formatDateTime(delivery.createdAt!) : '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeliveryDetailsScreen(deliveryId: delivery.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order #$orderNumber',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      delivery.statusDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.secondary : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Pickup location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup: $shopName',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          delivery.pickupAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dropoff location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drop-off Location',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          delivery.dropoffAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Bottom details & action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemsCount items • Total: ${CurrencyFormatter.formatLKR(totalAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Delivery Fee: ${CurrencyFormatter.formatLKR(fee)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeliveryMapScreen(deliveryId: delivery.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('View Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textLight.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}
