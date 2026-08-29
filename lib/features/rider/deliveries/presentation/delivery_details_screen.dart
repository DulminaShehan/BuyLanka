import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/features/rider/map/controllers/active_delivery_controller.dart';
import 'package:buylanka/features/rider/map/presentation/delivery_map_screen.dart';
import 'package:buylanka/models/delivery_model.dart';

class DeliveryDetailsScreen extends ConsumerWidget {
  final String deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesState = ref.watch(deliveriesControllerProvider);
    final mapState = ref.watch(activeDeliveryMapProvider(deliveryId));

    DeliveryModel? delivery;
    try {
      delivery = deliveriesState.deliveries.firstWhere((d) => d.id == deliveryId);
    } catch (_) {
      delivery = null;
    }

    if (delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Details')),
        body: const Center(child: Text('Delivery record not found')),
      );
    }

    final order = delivery.order;
    final orderNumber = order?.orderNumber ?? delivery.orderId.substring(0, 8).toUpperCase();
    final shop = order?.shop;
    final customer = order?.customer;
    final shopPhone = shop?.contactPhone ?? '+94 11 234 5678';
    final customerPhone = customer?.phoneNumber ?? '+94 77 987 6543';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeliveryMapScreen(deliveryId: deliveryId),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Status Banner
            _buildStatusHeader(delivery),

            const SizedBox(height: 16),

            // 2. Interactive Map Snapshot Preview
            if (mapState != null) _buildMapPreview(context, mapState, delivery),

            const SizedBox(height: 16),

            // 3. Restaurant / Pickup Card
            _buildLocationCard(
              context: context,
              icon: Icons.storefront_rounded,
              iconColor: AppColors.primary,
              title: 'Pickup Restaurant',
              name: shop?.name ?? 'Restaurant Location',
              address: delivery.pickupAddress,
              phone: shopPhone,
              isCurrentTarget: delivery.isBeforePickup,
              onNavigate: () {
                final lat = delivery!.pickupLatitude ?? 6.9271;
                final lng = delivery.pickupLongitude ?? 79.8612;
                MapUtils.launchNavigation(latitude: lat, longitude: lng, address: delivery.pickupAddress);
              },
            ),

            const SizedBox(height: 14),

            // 4. Customer / Drop-off Card
            _buildLocationCard(
              context: context,
              icon: Icons.location_on_rounded,
              iconColor: AppColors.secondary,
              title: 'Customer Drop-off',
              name: customer?.fullName ?? 'Customer Name',
              address: delivery.dropoffAddress,
              phone: customerPhone,
              isCurrentTarget: delivery.isAfterPickup,
              onNavigate: () {
                final lat = delivery!.dropoffLatitude ?? 6.8905;
                final lng = delivery.dropoffLongitude ?? 79.8732;
                MapUtils.launchNavigation(latitude: lat, longitude: lng, address: delivery.dropoffAddress);
              },
            ),

            const SizedBox(height: 16),

            // 5. Order Items & Bill Breakdown
            _buildOrderBreakdownCard(order, delivery),

            const SizedBox(height: 100), // Bottom button padding
          ],
        ),
      ),
      bottomSheet: delivery.isActive
          ? _buildActionBottomSheet(context, ref, delivery)
          : null,
    );
  }

  Widget _buildStatusHeader(DeliveryModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.statusDisplay,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery.isBeforePickup
                      ? 'Target: Pickup food at restaurant'
                      : (delivery.isAfterPickup
                          ? 'Target: Deliver food to customer'
                          : 'Order completed successfully'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context, ActiveDeliveryMapState mapState, DeliveryModel delivery) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mapState.destinationLocation,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buylanka.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: mapState.routePoints,
                    strokeWidth: 4,
                    color: AppColors.primary,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: mapState.riderLocation,
                    width: 32,
                    height: 32,
                    child: const Icon(Icons.navigation_rounded, color: AppColors.info, size: 28),
                  ),
                  Marker(
                    point: mapState.destinationLocation,
                    width: 32,
                    height: 32,
                    child: Icon(
                      mapState.isHeadingToShop ? Icons.storefront_rounded : Icons.location_on_rounded,
                      color: mapState.isHeadingToShop ? AppColors.primary : AppColors.secondary,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${mapState.distanceKm.toStringAsFixed(1)} km • ~${mapState.estimatedMinutes} min',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: ElevatedButton.icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.fullscreen_rounded, size: 16),
              label: const Text('Full Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String address,
    required String phone,
    required bool isCurrentTarget,
    required VoidCallback onNavigate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTarget ? AppColors.primary : AppColors.border,
          width: isCurrentTarget ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCurrentTarget ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              if (isCurrentTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CURRENT TARGET',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => MapUtils.makePhoneCall(phone),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16, color: AppColors.success),
                  label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBreakdownCard(dynamic order, DeliveryModel delivery) {
    final items = order?.items ?? [];
    final totalAmount = order?.totalAmount ?? 0.0;
    final deliveryFee = order?.deliveryFee ?? 350.0;
    final paymentMethod = (order?.paymentMethod ?? 'cod').toUpperCase();

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
          const Text(
            'Order Items & Payment',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Divider(height: 20),
          if (items.isEmpty)
            const Text('Standard Food & Delivery Order', style: TextStyle(color: AppColors.textLight))
          else
            ...items.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity}x ${item.productTitle}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Text(
                      CurrencyFormatter.formatLKR(item.totalPrice),
                      style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Mode', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentMethod,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Delivery Fee Earning', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
              Text(
                CurrencyFormatter.formatLKR(deliveryFee),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(
                CurrencyFormatter.formatLKR(totalAmount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBottomSheet(BuildContext context, WidgetRef ref, DeliveryModel delivery) {
    final nextAction = delivery.nextActionLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              if (delivery.isArrivedAtPickup || delivery.isArrivedAtCustomer) {
                // Show confirmation dialog before confirming pickup or final delivery
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(delivery.isArrivedAtPickup ? 'Confirm Pickup' : 'Confirm Delivery Handover'),
                    content: Text(delivery.isArrivedAtPickup
                        ? 'Have you collected all packed items from the restaurant?'
                        : 'Have you safely handed over the order to the customer?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
              }

              final success = await ref.read(deliveriesControllerProvider.notifier).advanceDeliveryStatus(delivery);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status updated to: ${delivery.nextStatus?.replaceAll('_', ' ').toUpperCase()}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              nextAction,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
