import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/core/utils/date_formatter.dart';
import 'package:buylanka/features/customer/orders/controllers/customer_orders_controller.dart';
import 'package:buylanka/features/customer/reviews/presentation/add_review_dialog.dart';
import 'package:buylanka/features/customer/tracking/presentation/live_order_tracking_screen.dart';
import 'package:buylanka/models/order_model.dart';

class CustomerOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const CustomerOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<CustomerOrderDetailsScreen> createState() => _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState extends ConsumerState<CustomerOrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final repo = ref.read(customerOrderRepositoryProvider);
    final order = await repo.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Receipt')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Receipt')),
        body: const Center(child: Text('Order record not found')),
      );
    }

    final shop = order.shop;
    final isActive = order.orderStatus != 'delivered' &&
        order.orderStatus != 'cancelled' &&
        order.orderStatus != 'rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Restaurant Header
            Container(
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
                        shop?.name ?? 'Restaurant',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      _buildStatusPill(order.orderStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (order.createdAt != null)
                    Text(
                      'Placed on ${DateFormatter.formatDateTime(order.createdAt!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: const Text('Track Live On Map', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Order Items Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const Divider(height: 20),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.productTitle,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.formatLKR(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      Text(CurrencyFormatter.formatLKR(order.deliveryFee), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: TextStyle(color: AppColors.success, fontSize: 13)),
                        Text('- ${CurrencyFormatter.formatLKR(order.discountAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid (COD)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(
                        CurrencyFormatter.formatLKR(order.totalAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Shipping Address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Delivery Destination', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.shippingAddress['street_address'] ?? order.shippingAddress['address'] ?? 'Colombo 05',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  if (order.shippingAddress['city'] != null)
                    Text(
                      order.shippingAddress['city'],
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Instructions: ${order.customerNotes}',
                      style: const TextStyle(fontSize: 12, color: AppColors.info, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Action Buttons (Review)
            if (order.orderStatus == 'delivered')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AddReviewDialog.show(context, orderId: order.id, shopId: order.shopId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Leave a Review ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    Color bg;

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
      default:
        color = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
