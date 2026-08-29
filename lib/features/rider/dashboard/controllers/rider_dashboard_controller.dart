import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:buylanka/core/location/location_service.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/rider/deliveries/controllers/deliveries_controller.dart';
import 'package:buylanka/models/rider_earnings_model.dart';
import 'package:buylanka/models/rider_model.dart';
import 'package:buylanka/repositories/rider_repository.dart';

class RiderDashboardState {
  final RiderModel? rider;
  final bool isOnline;
  final bool isTogglingStatus;
  final RiderEarningsModel earnings;
  final Position? currentPosition;
  final bool isLoading;
  final String? errorMessage;

  const RiderDashboardState({
    this.rider,
    this.isOnline = false,
    this.isTogglingStatus = false,
    this.earnings = const RiderEarningsModel(),
    this.currentPosition,
    this.isLoading = false,
    this.errorMessage,
  });

  RiderDashboardState copyWith({
    RiderModel? rider,
    bool? isOnline,
    bool? isTogglingStatus,
    RiderEarningsModel? earnings,
    Position? currentPosition,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RiderDashboardState(
      rider: rider ?? this.rider,
      isOnline: isOnline ?? this.isOnline,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      earnings: earnings ?? this.earnings,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RiderDashboardController extends StateNotifier<RiderDashboardState> {
  final RiderRepository _repository;
  final Ref _ref;
  StreamSubscription<Position>? _locationSubscription;

  RiderDashboardController(this._repository, this._ref) : super(const RiderDashboardState(isLoading: true)) {
    _init();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final authState = _ref.read(authControllerProvider);
    final rider = authState.rider;
    if (rider == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(
      rider: rider,
      isOnline: rider.isOnline,
      isLoading: true,
    );

    await Future.wait([
      _refreshEarnings(rider.id),
      _initLocationTracking(rider.id, rider.isOnline),
    ]);

    state = state.copyWith(isLoading: false);
  }

  Future<void> _refreshEarnings(String riderId) async {
    try {
      final earnings = await _repository.getRiderEarnings(riderId);
      state = state.copyWith(earnings: earnings);
    } catch (_) {}
  }

  /// Toggle Online / Offline availability status
  Future<void> toggleOnlineStatus() async {
    final rider = state.rider;
    if (rider == null) return;

    final newStatus = !state.isOnline;
    state = state.copyWith(isTogglingStatus: true, clearError: true);

    try {
      await _repository.toggleOnlineStatus(rider.id, newStatus);
      final updatedRider = rider.copyWith(isOnline: newStatus);

      state = state.copyWith(
        rider: updatedRider,
        isOnline: newStatus,
        isTogglingStatus: false,
      );

      // Start or stop live GPS tracking based on online status
      await _initLocationTracking(rider.id, newStatus);
    } catch (e) {
      state = state.copyWith(
        isTogglingStatus: false,
        errorMessage: 'Failed to update online status: $e',
      );
    }
  }

  Future<void> _initLocationTracking(String riderId, bool isOnline) async {
    _locationSubscription?.cancel();

    if (!isOnline) return;

    // Fetch initial GPS position
    final initialPos = await LocationService.getCurrentPosition();
    if (initialPos != null) {
      state = state.copyWith(currentPosition: initialPos);
      await _repository.updateLocation(
        riderId: riderId,
        latitude: initialPos.latitude,
        longitude: initialPos.longitude,
      );
    }

    // Subscribe to throttled GPS updates (15m delta, 10s interval)
    _locationSubscription = LocationService.getThrottledLocationStream().listen((pos) async {
      state = state.copyWith(currentPosition: pos);

      final activeDelivery = _ref.read(deliveriesControllerProvider).currentActiveDelivery;
      await _repository.updateLocation(
        riderId: riderId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        deliveryId: activeDelivery?.id,
        heading: pos.heading,
        speed: pos.speed,
      );
    });
  }

  Future<void> refresh() async {
    final rider = state.rider;
    if (rider != null) {
      await _refreshEarnings(rider.id);
    }
  }
}

final riderDashboardControllerProvider = StateNotifierProvider<RiderDashboardController, RiderDashboardState>((ref) {
  final repository = ref.watch(riderRepositoryProvider);
  return RiderDashboardController(repository, ref);
});
