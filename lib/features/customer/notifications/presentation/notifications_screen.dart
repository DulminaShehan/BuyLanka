import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/customer/notifications/controllers/notifications_controller.dart';
import 'package:buylanka/features/customer/tracking/presentation/live_order_tracking_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.textLight),
                      SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Order milestones and special offers will show up here.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = state.notifications[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: item.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          controller.markAsRead(item.id);
                          if (item.data['order_id'] != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LiveOrderTrackingScreen(orderId: item.data['order_id']),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          DateFormatter.formatDateTime(item.createdAt),
                                          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
