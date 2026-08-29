import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/features/rider/earnings/controllers/rider_earnings_controller.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsState = ref.watch(riderEarningsControllerProvider);
    final deliveriesState = ref.watch(deliveriesControllerProvider);
    final completedDeliveries = deliveriesState.completedDeliveries;
    final earnings = earningsState.earnings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings & Payouts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(riderEarningsControllerProvider.notifier).loadEarnings();
              ref.read(deliveriesControllerProvider.notifier).loadDeliveries();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(riderEarningsControllerProvider.notifier).loadEarnings();
          await ref.read(deliveriesControllerProvider.notifier).loadDeliveries();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Total / Today's Earnings Card
              _buildTodayHeroCard(earnings.todayEarnings, earnings.todayDeliveriesCount),

              const SizedBox(height: 16),

              // 2. Weekly & Monthly Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'This Week',
                      amount: earnings.weeklyEarnings,
                      tripsCount: earnings.weeklyDeliveriesCount,
                      icon: Icons.calendar_view_week_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'This Month',
                      amount: earnings.monthlyEarnings,
                      tripsCount: earnings.monthlyDeliveriesCount,
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. All-time career totals
              _buildCareerTotalsCard(earnings.totalEarnings, earnings.totalDeliveriesCount),

              const SizedBox(height: 24),

              // 4. Completed Payout Ledger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completed Trips & Fees',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${completedDeliveries.length} completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (completedDeliveries.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textLight),
                      SizedBox(height: 12),
                      Text(
                        'No completed deliveries yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Earnings from completed food and grocery deliveries will show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedDeliveries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final delivery = completedDeliveries[index];
                    final orderNumber = delivery.order?.orderNumber ?? delivery.orderId.substring(0, 8).toUpperCase();
                    final shopName = delivery.order?.shop?.name ?? 'Restaurant';
                    final fee = delivery.order?.deliveryFee ?? 350.0;
                    final dateStr = delivery.deliveredAt != null
                        ? DateFormatter.formatDateTime(delivery.deliveredAt!)
                        : (delivery.createdAt != null ? DateFormatter.formatDateTime(delivery.createdAt!) : '');

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #$orderNumber',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shopName,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                                  ),
                                  if (dateStr.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '+ ${CurrencyFormatter.formatLKR(fee)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
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

  Widget _buildTodayHeroCard(double todayEarnings, int todayCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                "Today's Net Earnings",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$todayCount Deliveries',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatLKR(todayEarnings),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.secondary, size: 16),
              SizedBox(width: 6),
              Text(
                'Live balance ready for weekly bank settlement',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required int tripsCount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.formatLKR(amount),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '$tripsCount trips completed',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerTotalsCard(double totalAmount, int totalTrips) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lifetime Career Deliveries',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '$totalTrips Total Orders Completed',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ],
          ),
          Text(
            CurrencyFormatter.formatLKR(totalAmount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
