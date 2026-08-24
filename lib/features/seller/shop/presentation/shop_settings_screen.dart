import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/seller/shop/controllers/shop_controller.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();

  String _openingTime = '08:00 AM';
  String _closingTime = '10:00 PM';
  String? _logoUrl;
  String? _bannerUrl;
  bool _isOpen = true;
  bool _isUploading = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(shopControllerProvider).shop;
      if (shop != null) {
        _nameController.text = shop.name;
        _descController.text = shop.description ?? '';
        _phoneController.text = shop.contactPhone ?? '';
        _addressController.text = shop.address ?? '';
        _cityController.text = shop.city ?? 'Colombo';
        _districtController.text = shop.district ?? 'Western';
        _openingTime = shop.openingTime ?? '08:00 AM';
        _closingTime = shop.closingTime ?? '10:00 PM';
        _logoUrl = shop.logoUrl;
        _bannerUrl = shop.bannerUrl;
        _isOpen = shop.isOpen;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(bool isBanner) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await ref.read(shopControllerProvider.notifier).uploadShopImage(
        file: file,
        isBanner: isBanner,
      );

      if (url != null && mounted) {
        setState(() {
          if (isBanner) {
            _bannerUrl = url;
          } else {
            _logoUrl = url;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveShopSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final currentShop = ref.read(shopControllerProvider).shop;
    if (currentShop == null) return;

    final updated = currentShop.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      openingTime: _openingTime,
      closingTime: _closingTime,
      logoUrl: _logoUrl,
      bannerUrl: _bannerUrl,
      isOpen: _isOpen,
    );

    final success = await ref.read(shopControllerProvider.notifier).updateShop(updated);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop settings updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(shopControllerProvider).errorMessage ?? 'Failed to update shop';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop & Restaurant Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            onPressed: shopState.isSaving ? null : _saveShopSettings,
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
              // Banner & Logo Preview Section
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  image: _bannerUrl != null && _bannerUrl!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(_bannerUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (_bannerUrl == null || _bannerUrl!.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, size: 36, color: AppColors.textMuted),
                            const SizedBox(height: 6),
                            Text('Add Cover Banner', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () => _pickAndUploadImage(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    // Logo Overlap
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: InkWell(
                        onTap: () => _pickAndUploadImage(false),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                            image: _logoUrl != null && _logoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(_logoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _logoUrl == null || _logoUrl!.isEmpty
                              ? const Center(
                                  child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Open / Close Toggle Card
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Accepting Orders (Store Open)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isOpen ? 'Store is open and visible to customers' : 'Store is paused / closed for delivery',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  activeThumbColor: AppColors.success,
                  value: _isOpen,
                  onChanged: (val) => setState(() => _isOpen = val),
                ),
              ),
              const SizedBox(height: 20),

              // Basic Info Section
              const Text('Shop Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop / Restaurant Name',
                  prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter shop name' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Cuisine Specialty',
                  alignLabelWithHint: true,
                  hintText: 'e.g. Authentic Sri Lankan spicy rice & curry, seafood specialties and kottu...',
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Store Contact Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter store phone' : null,
              ),
              const SizedBox(height: 24),

              // Location Section
              const Text('Location & Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City / Town'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'District / Province'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'District required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Operating Hours
              const Text('Daily Operating Hours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _openingTime,
                      decoration: const InputDecoration(labelText: 'Opens At'),
                      items: [
                        '06:00 AM',
                        '07:00 AM',
                        '08:00 AM',
                        '09:00 AM',
                        '10:00 AM',
                        '11:00 AM',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _openingTime = val ?? _openingTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _closingTime,
                      decoration: const InputDecoration(labelText: 'Closes At'),
                      items: [
                        '08:00 PM',
                        '09:00 PM',
                        '10:00 PM',
                        '11:00 PM',
                        '11:59 PM',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _closingTime = val ?? _closingTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: shopState.isSaving || _isUploading ? null : _saveShopSettings,
                child: shopState.isSaving || _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Shop Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
