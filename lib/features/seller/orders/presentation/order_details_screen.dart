import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/features/seller/orders/controllers/orders_controller.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch latest state of this order
    final ordersState = ref.watch(ordersControllerProvider);
    final currentOrder = ordersState.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentOrder.orderNumber),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, ref, currentOrder),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            _buildStatusHeader(currentOrder),
            const SizedBox(height: 16),

            // Customer & Delivery Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Information',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildInfoRow('Customer Name', currentOrder.customerName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Contact Phone', currentOrder.customerPhone),
                    const SizedBox(height: 8),
                    _buildInfoRow('Delivery Address', currentOrder.deliveryAddressText),
                    const SizedBox(height: 8),
                    _buildInfoRow('Order Placed At', DateFormatter.formatDateTime(currentOrder.createdAt)),

                    if (currentOrder.customerNotes != null && currentOrder.customerNotes!.isNotEmpty) ...[
                      const Divider(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Special Request: "${currentOrder.customerNotes}"',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ordered Food Items List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Ordered Food Items',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                        Text(
                          '${currentOrder.totalItemCount} Items',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentOrder.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = currentOrder.items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(item.unitPrice),
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment & Billing Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Payment & Bill Summary',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildBillRow('Subtotal Items', CurrencyFormatter.format(currentOrder.totalAmount - currentOrder.deliveryFee)),
                    const SizedBox(height: 8),
                    _buildBillRow('Estimated Delivery Fee', CurrencyFormatter.format(currentOrder.deliveryFee)),
                    if (currentOrder.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildBillRow('Discount', '- ${CurrencyFormatter.format(currentOrder.discountAmount)}', isDiscount: true),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          CurrencyFormatter.format(currentOrder.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            currentOrder.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order) {
    Color bg;
    Color text;
    String statusTitle;
    String statusSubtitle;
    IconData icon;

    switch (order.orderStatus) {
      case 'pending':
        bg = AppColors.warningBg;
        text = AppColors.statusPending;
        statusTitle = 'New Order Received';
        statusSubtitle = 'Please review items and accept to start preparing.';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'accepted':
      case 'preparing':
        bg = const Color(0xFFF3E8FF);
        text = AppColors.statusPreparing;
        statusTitle = 'Order is in Kitchen';
        statusSubtitle = 'Preparing food items. Mark ready when packed for rider.';
        icon = Icons.soup_kitchen_rounded;
        break;
      case 'ready_for_pickup':
        bg = AppColors.successBg;
        text = AppColors.statusReady;
        statusTitle = 'Ready for Pickup';
        statusSubtitle = 'Order packed. Waiting for BuyLanka delivery rider.';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'delivered':
        bg = AppColors.successBg;
        text = AppColors.success;
        statusTitle = 'Order Delivered';
        statusSubtitle = 'Successfully delivered to the customer.';
        icon = Icons.done_all_rounded;
        break;
      case 'cancelled':
        bg = AppColors.dangerBg;
        text = AppColors.danger;
        statusTitle = 'Order Cancelled';
        statusSubtitle = 'This order was rejected or cancelled.';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = AppColors.surfaceVariant;
        text = AppColors.textPrimary;
        statusTitle = order.orderStatus.toUpperCase();
        statusSubtitle = 'Order status updated.';
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: text.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: text, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 2),
                Text(statusSubtitle, style: TextStyle(fontSize: 12, color: text.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDiscount ? AppColors.danger : AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActionBar(BuildContext context, WidgetRef ref, OrderModel order) {
    final ordersController = ref.read(ordersControllerProvider.notifier);

    if (order.orderStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () async {
                  await ordersController.rejectOrder(order.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Reject Order'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => ordersController.acceptOrder(order.id),
                child: const Text('Accept & Prepare'),
              ),
            ),
          ],
        ),
      );
    } else if (order.orderStatus == 'accepted' || order.orderStatus == 'preparing') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark Ready for Rider Pickup'),
          onPressed: () => ordersController.markReadyForPickup(order.id),
        ),
      );
    }
    return null;
  }
}
