import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/customer/reviews/presentation/add_review_dialog.dart';
import 'package:buylanka/features/customer/tracking/controllers/live_tracking_controller.dart';
import 'package:buylanka/models/order_model.dart';

class LiveOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveOrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveOrderTrackingScreen> createState() => _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends ConsumerState<LiveOrderTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTrackingControllerProvider(widget.orderId));

    if (state.isLoading && state.order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Order Tracking')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final order = state.order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Order Tracking')),
        body: const Center(child: Text('Order record not found')),
      );
    }

    final delivery = state.delivery;
    final riderPos = state.liveRiderPosition;
    final shop = order.shop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
            tooltip: 'Support Hotline',
            onPressed: () => MapUtils.makePhoneCall('+94 11 200 9000'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live OpenStreetMap Preview
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: riderPos ?? state.shopLocation,
                    initialZoom: 13.5,
                    minZoom: 6.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.buylanka.app',
                    ),
                    if (state.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: state.routePoints,
                            strokeWidth: 4.5,
                            color: AppColors.primary,
                            borderColor: Colors.white,
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Restaurant Marker
                        Marker(
                          point: state.shopLocation,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                          ),
                        ),

                        // Customer Destination Marker
                        Marker(
                          point: state.customerLocation,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                          ),
                        ),

                        // Rider Live Position Marker (if active)
                        if (riderPos != null)
                          Marker(
                            point: riderPos,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(color: AppColors.info.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2),
                                ],
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // ETA Pill Overlay
                Positioned(
                  top: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          order.orderStatus == 'delivered'
                              ? 'Delivered'
                              : '~${state.estimatedMinutes} min estimated',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter Button
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'customer_recenter',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: () {
                      _mapController.move(riderPos ?? state.shopLocation, 14.5);
                    },
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),

          // 2. Order Status Stepper & Details Sheet
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant info header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop?.name ?? 'Restaurant',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.items.length} items • ${CurrencyFormatter.formatLKR(order.totalAmount)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                            ),
                          ],
                        ),
                        if (order.orderStatus == 'delivered')
                          ElevatedButton.icon(
                            onPressed: () {
                              AddReviewDialog.show(context, orderId: order.id, shopId: order.shopId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.star_rounded, size: 16),
                            label: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Rider info pill (if assigned)
                    if (delivery != null && delivery.isAssigned) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  radius: 18,
                                  child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Rider Assigned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(height: 2),
                                    Text('Contact driver for updates', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.call_rounded, color: AppColors.success),
                              onPressed: () => MapUtils.makePhoneCall('+94 77 123 4567'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Order Progress Stepper
                    _buildProgressTimeline(order, delivery),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(OrderModel order, dynamic delivery) {
    final status = order.orderStatus.toLowerCase();
    final isDelivered = status == 'delivered';
    final isOnTheWay = delivery != null && delivery.isAfterPickup;
    final isReadyOrPicked = status == 'ready_for_pickup' || status == 'picked_up' || isOnTheWay || isDelivered;
    final isPreparing = status == 'preparing' || status == 'accepted' || isReadyOrPicked;
    final isPlaced = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Milestones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildTimelineStep(
          title: 'Order Placed & Sent',
          subtitle: 'Restaurant has received your order',
          isDone: isPlaced,
          isActive: status == 'pending',
        ),
        _buildTimelineStep(
          title: 'Food in Preparation 👨‍🍳',
          subtitle: 'Kitchen is packing your fresh meal',
          isDone: isPreparing,
          isActive: status == 'preparing' || status == 'accepted',
        ),
        _buildTimelineStep(
          title: 'Rider Picked Up & On The Way 🚴',
          subtitle: 'Heading towards your delivery destination',
          isDone: isReadyOrPicked,
          isActive: isOnTheWay,
        ),
        _buildTimelineStep(
          title: 'Order Delivered 🎉',
          subtitle: 'Enjoy your food!',
          isDone: isDelivered,
          isActive: isDelivered,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final iconColor = isDone ? AppColors.success : (isActive ? AppColors.primary : AppColors.textLight);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_circle_rounded : (isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                color: iconColor,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDone || isActive ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
