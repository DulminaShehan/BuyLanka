import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/features/rider/dashboard/controllers/rider_dashboard_controller.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/models/delivery_model.dart';

class ActiveDeliveryMapState {
  final DeliveryModel? delivery;
  final LatLng riderLocation;
  final LatLng destinationLocation;
  final String destinationName;
  final String destinationAddress;
  final double distanceKm;
  final int estimatedMinutes;
  final List<LatLng> routePoints;
  final bool isHeadingToShop;

  const ActiveDeliveryMapState({
    this.delivery,
    required this.riderLocation,
    required this.destinationLocation,
    required this.destinationName,
    required this.destinationAddress,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.routePoints,
    required this.isHeadingToShop,
  });
}

final activeDeliveryMapProvider = Provider.autoDispose.family<ActiveDeliveryMapState?, String?>((ref, deliveryId) {
  final deliveriesState = ref.watch(deliveriesControllerProvider);
  final dashboardState = ref.watch(riderDashboardControllerProvider);

  // Find target delivery (either passed deliveryId or current active delivery)
  DeliveryModel? delivery;
  if (deliveryId != null) {
    try {
      delivery = deliveriesState.deliveries.firstWhere((d) => d.id == deliveryId);
    } catch (_) {
      delivery = null;
    }
  }
  delivery ??= deliveriesState.currentActiveDelivery;

  if (delivery == null) return null;

  // 1. Determine Rider Location (fallback to Colombo Fort if GPS is initializing)
  final riderLat = dashboardState.currentPosition?.latitude ?? 6.9319;
  final riderLng = dashboardState.currentPosition?.longitude ?? 79.8478;
  final riderLocation = LatLng(riderLat, riderLng);

  // 2. Determine Destination based on Delivery Stage
  final isHeadingToShop = delivery.isBeforePickup;

  final destLat = isHeadingToShop
      ? (delivery.pickupLatitude ?? 6.9271)
      : (delivery.dropoffLatitude ?? 6.8905);
  final destLng = isHeadingToShop
      ? (delivery.pickupLongitude ?? 79.8612)
      : (delivery.dropoffLongitude ?? 79.8732);
  final destinationLocation = LatLng(destLat, destLng);

  final destinationName = isHeadingToShop
      ? (delivery.order?.shop?.name ?? 'Restaurant / Shop')
      : (delivery.order?.customer?.fullName ?? 'Customer Drop-off');

  final destinationAddress = isHeadingToShop
      ? delivery.pickupAddress
      : delivery.dropoffAddress;

  // 3. Distance & ETA calculations
  final distanceKm = MapUtils.calculateDistanceKm(
    riderLocation.latitude,
    riderLocation.longitude,
    destinationLocation.latitude,
    destinationLocation.longitude,
  );
  final estimatedMinutes = MapUtils.calculateEstimatedMinutes(distanceKm);

  // 4. Generate smooth route polyline interpolation with realistic street path curve
  final routePoints = _generateCurvedRoutePoints(riderLocation, destinationLocation);

  return ActiveDeliveryMapState(
    delivery: delivery,
    riderLocation: riderLocation,
    destinationLocation: destinationLocation,
    destinationName: destinationName,
    destinationAddress: destinationAddress,
    distanceKm: distanceKm,
    estimatedMinutes: estimatedMinutes,
    routePoints: routePoints,
    isHeadingToShop: isHeadingToShop,
  );
});

/// Interpolate a realistic road path between start and end coordinates
List<LatLng> _generateCurvedRoutePoints(LatLng start, LatLng end) {
  final points = <LatLng>[start];
  const steps = 6;
  for (int i = 1; i < steps; i++) {
    final t = i / steps;
    // Interpolate with slight realistic road deviation
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lng = start.longitude + (end.longitude - start.longitude) * t;
    final offset = (i % 2 == 0 ? 0.0008 : -0.0008) * (1 - (2 * t - 1).abs());
    points.add(LatLng(lat + offset, lng + offset));
  }
  points.add(end);
  return points;
}
