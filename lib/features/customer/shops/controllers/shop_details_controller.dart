import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/review_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/customer_repository.dart';
import 'package:buylanka/repositories/favorite_repository.dart';
import 'package:buylanka/repositories/review_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/home/controllers/customer_home_controller.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

class ShopDetailsState {
  final ShopModel? shop;
  final List<ProductModel> products;
  final List<ReviewModel> reviews;
  final String? selectedCategory;
  final bool isFavorite;
  final bool isLoading;

  const ShopDetailsState({
    this.shop,
    this.products = const [],
    this.reviews = const [],
    this.selectedCategory,
    this.isFavorite = false,
    this.isLoading = false,
  });

  List<String> get availableCategories {
    final cats = products.map((p) => p.category?.name ?? 'Main Menu').toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategory == null || selectedCategory == 'All') return products;
    return products.where((p) => (p.category?.name ?? 'Main Menu') == selectedCategory).toList();
  }

  ShopDetailsState copyWith({
    ShopModel? shop,
    List<ProductModel>? products,
    List<ReviewModel>? reviews,
    String? selectedCategory,
    bool clearCategory = false,
    bool? isFavorite,
    bool? isLoading,
  }) {
    return ShopDetailsState(
      shop: shop ?? this.shop,
      products: products ?? this.products,
      reviews: reviews ?? this.reviews,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isFavorite: isFavorite ?? this.isFavorite,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ShopDetailsController extends StateNotifier<ShopDetailsState> {
  final String shopId;
  final CustomerRepository _customerRepo;
  final FavoriteRepository _favoriteRepo;
  final ReviewRepository _reviewRepo;
  final String? _customerId;

  ShopDetailsController({
    required this.shopId,
    required CustomerRepository customerRepo,
    required FavoriteRepository favoriteRepo,
    required ReviewRepository reviewRepo,
    String? customerId,
  })  : _customerRepo = customerRepo,
        _favoriteRepo = favoriteRepo,
        _reviewRepo = reviewRepo,
        _customerId = customerId,
        super(const ShopDetailsState(isLoading: true)) {
    loadShopDetails();
  }

  Future<void> loadShopDetails() async {
    state = state.copyWith(isLoading: true);
    try {
      final shop = await _customerRepo.getShopById(shopId);
      final products = await _customerRepo.getProductsByShop(shopId);
      final reviews = await _reviewRepo.getShopReviews(shopId);
      bool isFav = false;
      if (_customerId != null) {
        isFav = await _favoriteRepo.isShopFavorite(_customerId, shopId);
      }

      state = state.copyWith(
        shop: shop,
        products: products,
        reviews: reviews,
        isFavorite: isFav,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> toggleFavorite() async {
    if (_customerId == null) return;
    final newFav = await _favoriteRepo.toggleFavoriteShop(_customerId, shopId);
    state = state.copyWith(isFavorite: newFav);
  }
}

final shopDetailsControllerProvider = StateNotifierProvider.family<ShopDetailsController, ShopDetailsState, String>((ref, shopId) {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final favoriteRepo = ref.watch(favoriteRepositoryProvider);
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  final customerId = ref.watch(authControllerProvider).profile?.id;

  return ShopDetailsController(
    shopId: shopId,
    customerRepo: customerRepo,
    favoriteRepo: favoriteRepo,
    reviewRepo: reviewRepo,
    customerId: customerId,
  );
});
