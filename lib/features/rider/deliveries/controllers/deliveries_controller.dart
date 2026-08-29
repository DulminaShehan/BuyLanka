import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/models/delivery_model.dart';
import 'package:buylanka/repositories/rider_repository.dart';

class DeliveriesState {
  final List<DeliveryModel> deliveries;
  final bool isLoading;
  final String? errorMessage;

  const DeliveriesState({
    this.deliveries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<DeliveryModel> get activeDeliveries => deliveries.where((d) => d.isActive).toList();
  List<DeliveryModel> get completedDeliveries => deliveries.where((d) => d.isDelivered).toList();
  DeliveryModel? get currentActiveDelivery => activeDeliveries.isNotEmpty ? activeDeliveries.first : null;

  int get todayCompletedCount {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return completedDeliveries.where((d) {
      final date = d.deliveredAt ?? d.createdAt ?? DateTime.now();
      return date.isAfter(startOfToday);
    }).length;
  }

  DeliveriesState copyWith({
    List<DeliveryModel>? deliveries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeliveriesState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeliveriesController extends StateNotifier<DeliveriesState> {
  final RiderRepository _repository;
  final String? _riderId;
  StreamSubscription? _subscription;

  DeliveriesController(this._repository, this._riderId) : super(const DeliveriesState(isLoading: true)) {
    if (_riderId != null) {
      loadDeliveries();
      _listenToRealtimeStream();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadDeliveries() async {
    if (_riderId == null) return;
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final deliveries = await _repository.getAssignedDeliveries(_riderId);
      state = state.copyWith(deliveries: deliveries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load deliveries: ${e.toString()}',
      );
    }
  }

  void _listenToRealtimeStream() {
    if (_riderId == null) return;
    _subscription?.cancel();
    _subscription = _repository.streamRiderDeliveries(_riderId).listen((_) {
      loadDeliveries();
    });
  }

  /// Advance delivery status through the strict 8-step pipeline
  Future<bool> advanceDeliveryStatus(DeliveryModel delivery) async {
    final nextStatus = delivery.nextStatus;
    if (nextStatus == null) return false;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _repository.updateDeliveryStatus(
        deliveryId: delivery.id,
        orderId: delivery.orderId,
        newStatus: nextStatus,
      );
      await loadDeliveries();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update delivery status: $e',
      );
      return false;
    }
  }
}

final deliveriesControllerProvider = StateNotifierProvider<DeliveriesController, DeliveriesState>((ref) {
  final repository = ref.watch(riderRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final riderId = authState.rider?.id ?? authState.profile?.id;
  return DeliveriesController(repository, riderId);
});
