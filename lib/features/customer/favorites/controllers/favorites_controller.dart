import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/favorite_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/shops/controllers/shop_details_controller.dart';

class FavoritesState {
  final List<ShopModel> favoriteShops;
  final List<ProductModel> favoriteProducts;
  final bool isLoading;

  const FavoritesState({
    this.favoriteShops = const [],
    this.favoriteProducts = const [],
    this.isLoading = false,
  });

  FavoritesState copyWith({
    List<ShopModel>? favoriteShops,
    List<ProductModel>? favoriteProducts,
    bool? isLoading,
  }) {
    return FavoritesState(
      favoriteShops: favoriteShops ?? this.favoriteShops,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FavoritesController extends StateNotifier<FavoritesState> {
  final FavoriteRepository _repository;
  final String? _customerId;

  FavoritesController(this._repository, this._customerId) : super(const FavoritesState(isLoading: true)) {
    if (_customerId != null) {
      loadFavorites();
    }
  }

  Future<void> loadFavorites() async {
    if (_customerId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final shops = await _repository.getFavoriteShops(_customerId);
      final products = await _repository.getFavoriteProducts(_customerId);
      state = state.copyWith(
        favoriteShops: shops,
        favoriteProducts: products,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleShopFavorite(String shopId) async {
    if (_customerId == null) return;
    await _repository.toggleFavoriteShop(_customerId, shopId);
    await loadFavorites();
  }

  Future<void> toggleProductFavorite(String productId) async {
    if (_customerId == null) return;
    await _repository.toggleFavoriteProduct(_customerId, productId);
    await loadFavorites();
  }
}

final favoritesControllerProvider = StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final repo = ref.watch(favoriteRepositoryProvider);
  final customerId = ref.watch(authControllerProvider).profile?.id;
  return FavoritesController(repo, customerId);
});
