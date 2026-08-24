import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/repositories/product_repository.dart';
import 'package:buylanka/repositories/storage_repository.dart';
import 'package:buylanka/features/seller/shop/controllers/shop_controller.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductsStateData {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProductsStateData({
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  List<ProductModel> get filteredProducts {
    var list = products;
    if (selectedCategoryId != 'all') {
      list = list.where((p) => p.categoryId == selectedCategoryId).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) => p.title.toLowerCase().contains(q) || (p.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  ProductsStateData copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductsStateData(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductsController extends StateNotifier<ProductsStateData> {
  final ProductRepository _productRepository;
  final StorageRepository _storageRepository;
  final Ref _ref;

  ProductsController(this._productRepository, this._storageRepository, this._ref)
      : super(const ProductsStateData(isLoading: true)) {
    loadCategoriesAndProducts();
  }

  Future<void> loadCategoriesAndProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final categories = await _productRepository.getCategories();
      final shop = _ref.read(shopControllerProvider).shop;

      if (shop != null) {
        final products = await _productRepository.getProductsByShop(shop.id);
        state = state.copyWith(
          categories: categories,
          products: products,
          isLoading: false,
        );
      } else {
        state = state.copyWith(categories: categories, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setCategoryFilter(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createProduct(ProductModel product, {List<XFile>? newImages}) async {
    final shop = _ref.read(shopControllerProvider).shop;
    if (shop == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      List<String> uploadedUrls = List.from(product.images);

      if (newImages != null && newImages.isNotEmpty) {
        for (final file in newImages) {
          final url = await _storageRepository.uploadImage(
            bucket: SupabaseConstants.productImagesBucket,
            file: file,
            folder: shop.id,
          );
          if (url != null) uploadedUrls.add(url);
        }
      }

      final productToCreate = ProductModel(
        id: '',
        shopId: shop.id,
        categoryId: product.categoryId,
        title: product.title,
        slug: '',
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        stockQuantity: product.stockQuantity,
        sku: product.sku,
        images: uploadedUrls,
        isFeatured: product.isFeatured,
        isAvailable: product.isAvailable,
        preparationTimeMinutes: product.preparationTimeMinutes,
      );

      final created = await _productRepository.createProduct(productToCreate);

      state = state.copyWith(
        products: [created, ...state.products],
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product, {List<XFile>? newImages}) async {
    final shop = _ref.read(shopControllerProvider).shop;
    if (shop == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      List<String> uploadedUrls = List.from(product.images);

      if (newImages != null && newImages.isNotEmpty) {
        for (final file in newImages) {
          final url = await _storageRepository.uploadImage(
            bucket: SupabaseConstants.productImagesBucket,
            file: file,
            folder: shop.id,
          );
          if (url != null) uploadedUrls.add(url);
        }
      }

      final productToUpdate = product.copyWith(images: uploadedUrls);
      final updated = await _productRepository.updateProduct(productToUpdate);

      final updatedList = state.products.map((p) => p.id == updated.id ? updated : p).toList();
      state = state.copyWith(products: updatedList, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> toggleAvailability(String productId, bool isAvailable) async {
    final currentList = state.products;
    final updatedList = currentList.map((p) {
      if (p.id == productId) {
        return p.copyWith(isAvailable: isAvailable);
      }
      return p;
    }).toList();

    state = state.copyWith(products: updatedList);

    try {
      await _productRepository.toggleProductAvailability(productId, isAvailable);
    } catch (e) {
      // Revert
      state = state.copyWith(products: currentList);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    final currentList = state.products;
    final updatedList = currentList.where((p) => p.id != productId).toList();
    state = state.copyWith(products: updatedList);

    try {
      await _productRepository.deleteProduct(productId);
      return true;
    } catch (e) {
      state = state.copyWith(products: currentList, errorMessage: e.toString());
      return false;
    }
  }
}

final productsControllerProvider = StateNotifierProvider<ProductsController, ProductsStateData>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final storageRepo = ref.watch(storageRepositoryProvider);
  return ProductsController(productRepo, storageRepo, ref);
});
