import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/customer_repository.dart';
import 'package:buylanka/features/customer/home/controllers/customer_home_controller.dart';

class CustomerSearchState {
  final String query;
  final List<ProductModel> matchingProducts;
  final List<ShopModel> matchingShops;
  final bool isSearching;

  const CustomerSearchState({
    this.query = '',
    this.matchingProducts = const [],
    this.matchingShops = const [],
    this.isSearching = false,
  });

  bool get hasResults => matchingProducts.isNotEmpty || matchingShops.isNotEmpty;

  CustomerSearchState copyWith({
    String? query,
    List<ProductModel>? matchingProducts,
    List<ShopModel>? matchingShops,
    bool? isSearching,
  }) {
    return CustomerSearchState(
      query: query ?? this.query,
      matchingProducts: matchingProducts ?? this.matchingProducts,
      matchingShops: matchingShops ?? this.matchingShops,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class CustomerSearchController extends StateNotifier<CustomerSearchState> {
  final CustomerRepository _repository;

  CustomerSearchController(this._repository) : super(const CustomerSearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const CustomerSearchState();
      return;
    }

    state = state.copyWith(query: trimmed, isSearching: true);

    try {
      final products = await _repository.searchProducts(trimmed);
      final shops = await _repository.getShops(search: trimmed);

      state = state.copyWith(
        matchingProducts: products,
        matchingShops: shops,
        isSearching: false,
      );
    } catch (_) {
      state = state.copyWith(isSearching: false);
    }
  }

  void clear() {
    state = const CustomerSearchState();
  }
}

final customerSearchControllerProvider = StateNotifierProvider<CustomerSearchController, CustomerSearchState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerSearchController(repo);
});
