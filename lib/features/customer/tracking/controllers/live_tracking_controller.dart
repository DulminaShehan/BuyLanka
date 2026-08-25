import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/models/delivery_model.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/models/rider_location_model.dart';
import 'package:buylanka/repositories/customer_order_repository.dart';
import 'package:buylanka/features/customer/orders/controllers/customer_orders_controller.dart';

class LiveTrackingState {
  final OrderModel? order;
  final DeliveryModel? delivery;
  final RiderLocationModel? riderLocation;
  final LatLng shopLocation;
  final LatLng customerLocation;
  final LatLng? liveRiderPosition;
  final List<LatLng> routePoints;
  final double distanceKm;
  final int estimatedMinutes;
  final bool isLoading;

  const LiveTrackingState({
    this.order,
    this.delivery,
    this.riderLocation,
    required this.shopLocation,
    required this.customerLocation,
    this.liveRiderPosition,
    this.routePoints = const [],
    this.distanceKm = 0.0,
    this.estimatedMinutes = 20,
    this.isLoading = false,
  });

  bool get isRiderAssigned => delivery != null && delivery!.isAssigned;
  bool get isPickedUp => delivery != null && delivery!.isAfterPickup;
  bool get isDelivered => order?.orderStatus == 'delivered';

  LiveTrackingState copyWith({
    OrderModel? order,
    DeliveryModel? delivery,
    RiderLocationModel? riderLocation,
    LatLng? shopLocation,
    LatLng? customerLocation,
    LatLng? liveRiderPosition,
    List<LatLng>? routePoints,
    double? distanceKm,
    int? estimatedMinutes,
    bool? isLoading,
  }) {
    return LiveTrackingState(
      order: order ?? this.order,
      delivery: delivery ?? this.delivery,
      riderLocation: riderLocation ?? this.riderLocation,
      shopLocation: shopLocation ?? this.shopLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      liveRiderPosition: liveRiderPosition ?? this.liveRiderPosition,
      routePoints: routePoints ?? this.routePoints,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LiveTrackingController extends StateNotifier<LiveTrackingState> {
  final String orderId;
  final CustomerOrderRepository _orderRepo;
  StreamSubscription? _orderSub;
  StreamSubscription? _deliverySub;
  StreamSubscription? _riderLocSub;

  LiveTrackingController({
    required this.orderId,
    required CustomerOrderRepository orderRepo,
  })  : _orderRepo = orderRepo,
        super(const LiveTrackingState(
          shopLocation: LatLng(6.9271, 79.8612), // Colombo Default
          customerLocation: LatLng(6.8905, 79.8732),
          isLoading: true,
        )) {
    _initTracking();
  }

  Future<void> _initTracking() async {
    final order = await _orderRepo.getOrderById(orderId);
    if (order != null) {
      _updateWithOrder(order);
    }

    // 1. Subscribe to order status changes
    _orderSub = _orderRepo.streamOrder(orderId).listen((records) {
      if (records.isNotEmpty) {
        final updated = OrderModel.fromJson(records.first);
        _updateWithOrder(updated);
      }
    });

    // 2. Subscribe to delivery record
    _deliverySub = _orderRepo.streamDelivery(orderId).listen((deliveries) {
      if (deliveries.isNotEmpty) {
        final delivery = DeliveryModel.fromJson(deliveries.first);
        _updateWithDelivery(delivery);
      }
    });
  }

  void _updateWithOrder(OrderModel order) {
    state = state.copyWith(order: order, isLoading: false);
  }

  void _updateWithDelivery(DeliveryModel delivery) {
    final shopLat = delivery.pickupLatitude ?? 6.9271;
    final shopLng = delivery.pickupLongitude ?? 79.8612;
    final custLat = delivery.dropoffLatitude ?? 6.8905;
    final custLng = delivery.dropoffLongitude ?? 79.8732;

    final shopLoc = LatLng(shopLat, shopLng);
    final custLoc = LatLng(custLat, custLng);

    state = state.copyWith(
      delivery: delivery,
      shopLocation: shopLoc,
      customerLocation: custLoc,
    );

    // Subscribe to live GPS breadcrumbs for rider
    if (delivery.id.isNotEmpty) {
      _riderLocSub?.cancel();
      _riderLocSub = _orderRepo.streamRiderLocation(delivery.id).listen((locations) {
        if (locations.isNotEmpty) {
          final loc = RiderLocationModel.fromJson(locations.first);
          final riderPos = LatLng(loc.latitude, loc.longitude);
          final target = delivery.isAfterPickup ? custLoc : shopLoc;
          final dist = MapUtils.calculateDistanceKm(loc.latitude, loc.longitude, target.latitude, target.longitude);
          final eta = MapUtils.calculateEstimatedMinutes(dist);

          state = state.copyWith(
            riderLocation: loc,
            liveRiderPosition: riderPos,
            distanceKm: dist,
            estimatedMinutes: eta,
            routePoints: [riderPos, target],
          );
        }
      });
    }

    // Default route polyline
    if (state.liveRiderPosition == null) {
      final dist = MapUtils.calculateDistanceKm(shopLat, shopLng, custLat, custLng);
      state = state.copyWith(
        distanceKm: dist,
        estimatedMinutes: MapUtils.calculateEstimatedMinutes(dist),
        routePoints: [shopLoc, custLoc],
      );
    }
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _deliverySub?.cancel();
    _riderLocSub?.cancel();
    super.dispose();
  }
}

final liveTrackingControllerProvider = StateNotifierProvider.family<LiveTrackingController, LiveTrackingState, String>((ref, orderId) {
  final repo = ref.watch(customerOrderRepositoryProvider);
  return LiveTrackingController(orderId: orderId, orderRepo: repo);
});
