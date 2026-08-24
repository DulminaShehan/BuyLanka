import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/features/seller/products/controllers/products_controller.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _prepTimeController = TextEditingController();

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isFeatured = false;

  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final _imagePicker = ImagePicker();

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _titleController.text = p.title;
      _descController.text = p.description ?? '';
      _priceController.text = p.price.toStringAsFixed(0);
      if (p.originalPrice != null) {
        _originalPriceController.text = p.originalPrice!.toStringAsFixed(0);
      }
      _stockController.text = p.stockQuantity.toString();
      _prepTimeController.text = p.preparationTimeMinutes.toString();
      _selectedCategoryId = p.categoryId;
      _isAvailable = p.isAvailable;
      _isFeatured = p.isFeatured;
      _existingImages.addAll(p.images);
    } else {
      _stockController.text = '50';
      _prepTimeController.text = '15';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _newImages.add(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final originalPrice = double.tryParse(_originalPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 15;

    bool success = false;

    if (isEdit) {
      final updated = widget.product!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        originalPrice: originalPrice,
        stockQuantity: stock,
        preparationTimeMinutes: prepTime,
        categoryId: _selectedCategoryId,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        images: _existingImages,
      );

      success = await ref.read(productsControllerProvider.notifier).updateProduct(
        updated,
        newImages: _newImages,
      );
    } else {
      final newProduct = ProductModel(
        id: '',
        shopId: '',
        title: _titleController.text.trim(),
        slug: '',
        description: _descController.text.trim(),
        price: price,
        originalPrice: originalPrice,
        stockQuantity: stock,
        preparationTimeMinutes: prepTime,
        categoryId: _selectedCategoryId,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        images: _existingImages,
      );

      success = await ref.read(productsControllerProvider.notifier).createProduct(
        newProduct,
        newImages: _newImages,
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Menu item updated!' : 'Food item added to menu!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(productsControllerProvider).errorMessage ?? 'Failed to save product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!isEdit) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: Text('Are you sure you want to remove "${widget.product!.title}" from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(productsControllerProvider.notifier).deleteProduct(widget.product!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsControllerProvider);
    final categories = productsState.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Menu Item' : 'Add Food / Menu Item'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Selector
              const Text('Food Images', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),

              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Button
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Existing Images
                    ..._existingImages.map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => setState(() => _existingImages.remove(url)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // New Local Images
                    ..._newImages.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(file.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => setState(() => _newImages.remove(file)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Dish / Item Title',
                  hintText: 'e.g. Special Seafood Kottu Roti',
                  prefixIcon: Icon(Icons.fastfood_rounded, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item title' : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Menu Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),

              // Price & Discount Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs.)',
                        hintText: '850',
                        prefixText: 'Rs. ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(val) == null) return 'Valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Original Price (Rs.)',
                        hintText: 'Optional discount',
                        prefixText: 'Rs. ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stock & Prep Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Stock / Portions',
                        hintText: '50',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (Mins)',
                        hintText: '15',
                        suffixText: 'mins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description Input
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ingredients / Description',
                  hintText: 'Detailed description of the meal, spice level, portion size...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),

              // Availability Switch
              Card(
                child: SwitchListTile(
                  title: const Text('Available for Ordering', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    _isAvailable ? 'Customers can order this dish now' : 'Item is sold out / hidden from menu',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  activeThumbColor: AppColors.success,
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: productsState.isSaving ? null : _handleSave,
                child: productsState.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save Dish Changes' : 'Add to Restaurant Menu'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
