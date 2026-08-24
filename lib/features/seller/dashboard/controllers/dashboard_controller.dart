import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/features/seller/orders/controllers/orders_controller.dart';
import 'package:buylanka/features/seller/products/controllers/products_controller.dart';

class DashboardMetrics {
  final double todayRevenue;
  final int todayOrdersCount;
  final int pendingOrdersCount;
  final int preparingOrdersCount;
  final int readyOrdersCount;
  final int completedOrdersCount;
  final int lowStockProductsCount;

  const DashboardMetrics({
    this.todayRevenue = 0.0,
    this.todayOrdersCount = 0,
    this.pendingOrdersCount = 0,
    this.preparingOrdersCount = 0,
    this.readyOrdersCount = 0,
    this.completedOrdersCount = 0,
    this.lowStockProductsCount = 0,
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final ordersState = ref.watch(ordersControllerProvider);
  final productsState = ref.watch(productsControllerProvider);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  final todayOrders = ordersState.orders.where((o) {
    return o.createdAt != null && o.createdAt!.isAfter(startOfDay);
  }).toList();

  final todayRevenue = todayOrders
      .where((o) => o.orderStatus != 'cancelled')
      .fold<double>(0.0, (sum, o) => sum + o.totalAmount);

  final pendingCount = ordersState.newOrders.length;
  final preparingCount = ordersState.preparingOrders.length;
  final readyCount = ordersState.readyOrders.length;
  final completedCount = ordersState.orders.where((o) => o.orderStatus == 'delivered').length;

  final lowStockCount = productsState.products.where((p) => p.stockQuantity <= 5 && p.isAvailable).length;

  return DashboardMetrics(
    todayRevenue: todayRevenue,
    todayOrdersCount: todayOrders.length,
    pendingOrdersCount: pendingCount,
    preparingOrdersCount: preparingCount,
    readyOrdersCount: readyCount,
    completedOrdersCount: completedCount,
    lowStockProductsCount: lowStockCount,
  );
});
