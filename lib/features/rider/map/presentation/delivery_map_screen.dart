import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/features/rider/map/controllers/active_delivery_controller.dart';

class DeliveryMapScreen extends ConsumerStatefulWidget {
  final String? deliveryId;

  const DeliveryMapScreen({super.key, this.deliveryId});

  @override
  ConsumerState<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends ConsumerState<DeliveryMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(activeDeliveryMapProvider(widget.deliveryId));
    final deliveriesNotifier = ref.read(deliveriesControllerProvider.notifier);

    if (mapState == null || mapState.delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Delivery Map')),
        body: const Center(
          child: Text('No active delivery selected for navigation'),
        ),
      );
    }

    final delivery = mapState.delivery!;
    final order = delivery.order;
    final shopPhone = order?.shop?.contactPhone ?? '+94 11 234 5678';
    final customerPhone = order?.customer?.phoneNumber ?? '+94 77 987 6543';
    final targetPhone = mapState.isHeadingToShop ? shopPhone : customerPhone;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.riderLocation,
              initialZoom: 14.5,
              minZoom: 6.0,
              maxZoom: 18.0,
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
                    strokeWidth: 5,
                    color: AppColors.primary,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Rider Marker
                  Marker(
                    point: mapState.riderLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                    ),
                  ),

                  // Destination Marker
                  Marker(
                    point: mapState.destinationLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: mapState.isHeadingToShop ? AppColors.primary : AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        mapState.isHeadingToShop ? Icons.storefront_rounded : Icons.location_on_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Navigation Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    // Stage status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: mapState.isHeadingToShop ? AppColors.primary : AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mapState.isHeadingToShop ? 'Heading to Restaurant' : 'Delivering to Customer',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),

                    // External Google Navigation Launcher
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                        tooltip: 'Start Turn-by-Turn Navigation',
                        onPressed: () {
                          MapUtils.launchNavigation(
                            latitude: mapState.destinationLocation.latitude,
                            longitude: mapState.destinationLocation.longitude,
                            address: mapState.destinationAddress,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Recenter Camera Floating Button
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              heroTag: 'recenter_fab',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: () {
                _mapController.move(mapState.riderLocation, 15.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 4. Bottom Active Delivery Navigation Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance & ETA Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${mapState.distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '~${mapState.estimatedMinutes} min',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_rounded, color: AppColors.success),
                        onPressed: () => MapUtils.makePhoneCall(targetPhone),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Destination Name & Address
                  Text(
                    mapState.destinationName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mapState.destinationAddress,
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Big Prominent Workflow Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (delivery.isArrivedAtPickup || delivery.isArrivedAtCustomer) {
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

                        final success = await deliveriesNotifier.advanceDeliveryStatus(delivery);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delivery updated: ${delivery.nextStatus?.replaceAll('_', ' ').toUpperCase()}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          if (delivery.isArrivedAtCustomer) {
                            // Returned to deliveries list after final delivery
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        delivery.nextActionLabel.toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
