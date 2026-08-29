import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/order_model.dart';
import 'package:buylanka/repositories/customer_order_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

final customerOrderRepositoryProvider = Provider<CustomerOrderRepository>((ref) {
  return CustomerOrderRepository();
});

class CustomerOrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;

  const CustomerOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<OrderModel> get activeOrders => orders.where((o) {
        return o.orderStatus != 'delivered' &&
            o.orderStatus != 'cancelled' &&
            o.orderStatus != 'rejected';
      }).toList();

  List<OrderModel> get completedOrders => orders.where((o) => o.orderStatus == 'delivered').toList();

  List<OrderModel> get cancelledOrders => orders.where((o) => o.orderStatus == 'cancelled' || o.orderStatus == 'rejected').toList();

  CustomerOrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CustomerOrdersController extends StateNotifier<CustomerOrdersState> {
  final CustomerOrderRepository _repository;
  final String? _customerId;

  CustomerOrdersController(this._repository, this._customerId) : super(const CustomerOrdersState(isLoading: true)) {
    if (_customerId != null) {
      loadOrders();
    }
  }

  Future<void> loadOrders() async {
    if (_customerId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repository.getCustomerOrders(_customerId);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load orders. Please swipe down to retry.',
      );
    }
  }
}

final customerOrdersControllerProvider = StateNotifierProvider<CustomerOrdersController, CustomerOrdersState>((ref) {
  final repo = ref.watch(customerOrderRepositoryProvider);
  final customerId = ref.watch(authControllerProvider).profile?.id;
  return CustomerOrdersController(repo, customerId);
});
