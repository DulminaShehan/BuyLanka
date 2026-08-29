import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerHomeState {
  final List<CategoryModel> categories;
  final List<ShopModel> nearbyShops;
  final List<ShopModel> popularShops;
  final List<ProductModel> featuredProducts;
  final CategoryModel? selectedCategory;
  final bool isLoading;
  final String? errorMessage;
  final String currentDeliveryAddress;

  const CustomerHomeState({
    this.categories = const [],
    this.nearbyShops = const [],
    this.popularShops = const [],
    this.featuredProducts = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.errorMessage,
    this.currentDeliveryAddress = 'Colombo 05, Western Province',
  });

  CustomerHomeState copyWith({
    List<CategoryModel>? categories,
    List<ShopModel>? nearbyShops,
    List<ShopModel>? popularShops,
    List<ProductModel>? featuredProducts,
    CategoryModel? selectedCategory,
    bool clearSelectedCategory = false,
    bool? isLoading,
    String? errorMessage,
    String? currentDeliveryAddress,
  }) {
    return CustomerHomeState(
      categories: categories ?? this.categories,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      popularShops: popularShops ?? this.popularShops,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentDeliveryAddress: currentDeliveryAddress ?? this.currentDeliveryAddress,
    );
  }
}

class CustomerHomeController extends StateNotifier<CustomerHomeState> {
  final CustomerRepository _repository;

  CustomerHomeController(this._repository) : super(const CustomerHomeState(isLoading: true)) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _repository.getCategories();
      final nearbyShops = await _repository.getShops();
      final popularShops = await _repository.getPopularShops();
      final featuredProducts = await _repository.getFeaturedProducts();

      state = state.copyWith(
        categories: categories,
        nearbyShops: nearbyShops,
        popularShops: popularShops,
        featuredProducts: featuredProducts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load home feed. Please swipe down to refresh.',
      );
    }
  }

  void selectCategory(CategoryModel? category) {
    if (state.selectedCategory?.id == category?.id) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void updateDeliveryLocation(String address) {
    state = state.copyWith(currentDeliveryAddress: address);
  }
}

final customerHomeControllerProvider = StateNotifierProvider<CustomerHomeController, CustomerHomeState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerHomeController(repo);
});
