import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/repositories/order_repository.dart';
import 'package:buylanka/features/seller/shop/controllers/shop_controller.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

enum OrderTab { newOrders, preparing, readyForPickup, history }

class OrdersStateData {
  final List<OrderModel> orders;
  final OrderTab activeTab;
  final bool isLoading;
  final String? errorMessage;

  const OrdersStateData({
    this.orders = const [],
    this.activeTab = OrderTab.newOrders,
    this.isLoading = false,
    this.errorMessage,
  });

  List<OrderModel> get newOrders => orders.where((o) => o.orderStatus == 'pending').toList();

  List<OrderModel> get preparingOrders =>
      orders.where((o) => o.orderStatus == 'accepted' || o.orderStatus == 'preparing').toList();

  List<OrderModel> get readyOrders => orders.where((o) => o.orderStatus == 'ready_for_pickup').toList();

  List<OrderModel> get historyOrders =>
      orders.where((o) => ['shipped', 'delivered', 'cancelled', 'returned'].contains(o.orderStatus)).toList();

  List<OrderModel> get currentTabOrders {
    switch (activeTab) {
      case OrderTab.newOrders:
        return newOrders;
      case OrderTab.preparing:
        return preparingOrders;
      case OrderTab.readyForPickup:
        return readyOrders;
      case OrderTab.history:
        return historyOrders;
    }
  }

  OrdersStateData copyWith({
    List<OrderModel>? orders,
    OrderTab? activeTab,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersStateData(
      orders: orders ?? this.orders,
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrdersController extends StateNotifier<OrdersStateData> {
  final OrderRepository _orderRepository;
  final Ref _ref;
  StreamSubscription? _orderSubscription;

  OrdersController(this._orderRepository, this._ref) : super(const OrdersStateData(isLoading: true)) {
    loadOrders();
    _subscribeToRealtimeOrders();
  }

  Future<void> loadOrders() async {
    final shop = _ref.read(shopControllerProvider).shop;
    if (shop == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final orders = await _orderRepository.getOrdersByShop(shop.id);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _subscribeToRealtimeOrders() {
    final shop = _ref.read(shopControllerProvider).shop;
    if (shop == null) return;

    _orderSubscription?.cancel();
    _orderSubscription = _orderRepository.streamShopOrders(shop.id).listen(
      (_) {
        // When Realtime payload is detected, refresh orders with complete join data
        loadOrders();
      },
      onError: (err) {
        // Log stream error silently without disrupting UI
      },
    );
  }

  void setTab(OrderTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> acceptOrder(String orderId) async {
    _optimisticUpdate(orderId, 'accepted');
    try {
      await _orderRepository.acceptOrder(orderId);
    } catch (e) {
      loadOrders();
    }
  }

  Future<void> startPreparing(String orderId) async {
    _optimisticUpdate(orderId, 'preparing');
    try {
      await _orderRepository.startPreparing(orderId);
    } catch (e) {
      loadOrders();
    }
  }

  Future<void> markReadyForPickup(String orderId) async {
    _optimisticUpdate(orderId, 'ready_for_pickup');
    try {
      await _orderRepository.markReadyForPickup(orderId);
    } catch (e) {
      loadOrders();
    }
  }

  Future<void> rejectOrder(String orderId, {String? reason}) async {
    _optimisticUpdate(orderId, 'cancelled');
    try {
      await _orderRepository.cancelOrder(orderId, reason: reason);
    } catch (e) {
      loadOrders();
    }
  }

  void _optimisticUpdate(String orderId, String newStatus) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(orderStatus: newStatus);
      }
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}

final ordersControllerProvider = StateNotifierProvider<OrdersController, OrdersStateData>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return OrdersController(orderRepo, ref);
});
