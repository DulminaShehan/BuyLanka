import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/shop_repository.dart';
import 'package:buylanka/repositories/storage_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

class ShopStateData {
  final ShopModel? shop;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ShopStateData({
    this.shop,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ShopStateData copyWith({
    ShopModel? shop,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShopStateData(
      shop: shop ?? this.shop,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ShopController extends StateNotifier<ShopStateData> {
  final ShopRepository _shopRepository;
  final StorageRepository _storageRepository;
  final Ref _ref;

  ShopController(this._shopRepository, this._storageRepository, this._ref)
      : super(const ShopStateData(isLoading: true)) {
    loadShop();
  }

  Future<void> loadShop() async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.profile;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      var shop = await _shopRepository.getShopBySellerId(user.id);
      if (shop == null) {
        final businessName = authState.seller?.businessName ?? user.fullName;
        shop = await _shopRepository.createDefaultShop(user.id, businessName);
      }

      state = state.copyWith(shop: shop, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateShop(ShopModel updatedShop) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _shopRepository.updateShop(updatedShop);
      state = state.copyWith(shop: saved, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> toggleOpenStatus(bool isOpen) async {
    final currentShop = state.shop;
    if (currentShop == null) return;

    // Optimistic UI update
    state = state.copyWith(shop: currentShop.copyWith(isOpen: isOpen));

    try {
      await _shopRepository.toggleShopOpenStatus(currentShop.id, isOpen);
    } catch (e) {
      // Revert if failed
      state = state.copyWith(shop: currentShop);
    }
  }

  Future<String?> uploadShopImage({required XFile file, required bool isBanner}) async {
    final currentShop = state.shop;
    if (currentShop == null) return null;

    try {
      final url = await _storageRepository.uploadImage(
        bucket: SupabaseConstants.shopImagesBucket,
        file: file,
        folder: currentShop.id,
      );
      return url;
    } catch (e) {
      return null;
    }
  }
}

final shopControllerProvider = StateNotifierProvider<ShopController, ShopStateData>((ref) {
  final shopRepo = ref.watch(shopRepositoryProvider);
  final storageRepo = ref.watch(storageRepositoryProvider);
  return ShopController(shopRepo, storageRepo, ref);
});
