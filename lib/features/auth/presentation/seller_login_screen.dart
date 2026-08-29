import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/location_service.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

enum PartnerRole { restaurant, rider }

class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> with SingleTickerProviderStateMixin {
  PartnerRole _selectedRole = PartnerRole.restaurant;
  late TabController _tabController;

  static const List<String> _districts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  // Sign In Controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInObscure = true;
  final _signInFormKey = GlobalKey<FormState>();

  // Restaurant Register Controllers
  final _sellerOwnerNameController = TextEditingController();
  final _sellerShopNameController = TextEditingController();
  final _sellerEmailController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerAddressController = TextEditingController();
  final _sellerCityController = TextEditingController();
  String _sellerDistrict = 'Colombo';
  final _sellerPasswordController = TextEditingController();
  bool _sellerObscure = true;
  bool _isLocating = false;
  final _sellerFormKey = GlobalKey<FormState>();

  // Rider Register Controllers
  final _riderNameController = TextEditingController();
  final _riderEmailController = TextEditingController();
  final _riderPhoneController = TextEditingController();
  final _riderVehicleNumController = TextEditingController();
  final _riderLicenseController = TextEditingController();
  final _riderPasswordController = TextEditingController();
  String _selectedVehicleType = 'motorcycle';
  bool _riderObscure = true;
  final _riderFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _sellerOwnerNameController.dispose();
    _sellerShopNameController.dispose();
    _sellerEmailController.dispose();
    _sellerPhoneController.dispose();
    _sellerAddressController.dispose();
    _sellerCityController.dispose();
    _sellerPasswordController.dispose();
    _riderNameController.dispose();
    _riderEmailController.dispose();
    _riderPhoneController.dispose();
    _riderVehicleNumController.dispose();
    _riderLicenseController.dispose();
    _riderPasswordController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location coordinates detected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        if (_sellerCityController.text.trim().isEmpty) {
          _sellerCityController.text = _sellerDistrict;
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to detect GPS position. Please enter address manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _showPendingApprovalDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(0);
              _sellerOwnerNameController.clear();
              _sellerShopNameController.clear();
              _sellerEmailController.clear();
              _sellerPhoneController.clear();
              _sellerAddressController.clear();
              _sellerCityController.clear();
              _sellerDistrict = 'Colombo';
              _sellerPasswordController.clear();
              _riderNameController.clear();
              _riderEmailController.clear();
              _riderPhoneController.clear();
              _riderVehicleNumController.clear();
              _riderLicenseController.clear();
              _riderPasswordController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back to Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Customer Portal',
        ),
        title: const Text(
          'Partner Portal',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 1. Role Selection Header (Restaurant vs Rider)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        role: PartnerRole.restaurant,
                        title: 'Restaurant Partner',
                        subtitle: 'Manage shop & food menu',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        role: PartnerRole.rider,
                        title: 'Delivery Rider',
                        subtitle: 'Deliver orders & earn',
                        icon: Icons.two_wheeler_rounded,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Sign In vs Register Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _selectedRole == PartnerRole.restaurant ? AppColors.primary : const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textLight,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(text: 'Sign In'),
                    Tab(text: _selectedRole == PartnerRole.restaurant ? 'Register Restaurant' : 'Register as Rider'),
                  ],
                ),
              ),

              if (authState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 3. Tab Views
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignInView(authState.isLoading),
                    _selectedRole == PartnerRole.restaurant
                        ? _buildRestaurantRegisterView(authState.isLoading)
                        : _buildRiderRegisterView(authState.isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required PartnerRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Sign In View (Common for Restaurant & Rider) ---
  Widget _buildSignInView(bool isLoading) {
    final isRestaurant = _selectedRole == PartnerRole.restaurant;
    final primaryColor = isRestaurant ? AppColors.primary : const Color(0xFF1B5E20);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isRestaurant ? Icons.storefront_rounded : Icons.two_wheeler_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRestaurant
                          ? 'Sign in to manage orders and menu for your shop.'
                          : 'Sign in to start receiving delivery jobs.',
                      style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isRestaurant ? 'Restaurant Email' : 'Rider Registered Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _signInPasswordController,
              obscureText: _signInObscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_signInObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _signInObscure = !_signInObscure),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_signInFormKey.currentState?.validate() ?? false) {
                          final success = await ref.read(authControllerProvider.notifier).signIn(
                                email: _signInEmailController.text.trim(),
                                password: _signInPasswordController.text,
                              );
                          if (success && context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else if (!success && context.mounted) {
                            final err = ref.read(authControllerProvider).errorMessage ?? 'Login failed. Please check credentials.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isRestaurant ? 'Sign In as Restaurant' : 'Sign In as Rider',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Restaurant Partner Registration ---
  Widget _buildRestaurantRegisterView(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _sellerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Applications are reviewed and approved by BuyLanka Super Admin before store activation.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF795548), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _sellerShopNameController,
              decoration: InputDecoration(
                labelText: 'Restaurant / Shop Name',
                hintText: 'e.g. Royal Taste Kottu & Biryani',
                prefixIcon: const Icon(Icons.store_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter restaurant name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sellerOwnerNameController,
              decoration: InputDecoration(
                labelText: 'Owner / Manager Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter owner name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sellerEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Business Email Address',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sellerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone (e.g. 0771234567)',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
            const SizedBox(height: 14),

            // Location Header & GPS Auto-fill
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'Restaurant Location',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                InkWell(
                  onTap: _isLocating ? null : _detectCurrentLocation,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLocating)
                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        else
                          const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _isLocating ? 'Locating...' : 'GPS Auto-fill',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Street Address
            TextFormField(
              controller: _sellerAddressController,
              decoration: InputDecoration(
                labelText: 'Shop Street Address / Landmark',
                hintText: 'e.g. No. 45, Galle Road, Bambalapitiya',
                prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter restaurant street address' : null,
            ),
            const SizedBox(height: 12),

            // City and District Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _sellerCityController,
                    decoration: InputDecoration(
                      labelText: 'City / Town',
                      hintText: 'e.g. Colombo 04',
                      prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sellerDistrict,
                    decoration: InputDecoration(
                      labelText: 'District',
                      prefixIcon: const Icon(Icons.map_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    isExpanded: true,
                    items: _districts
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sellerDistrict = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sellerPasswordController,
              obscureText: _sellerObscure,
              decoration: InputDecoration(
                labelText: 'Create Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_sellerObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _sellerObscure = !_sellerObscure),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_sellerFormKey.currentState?.validate() ?? false) {
                          final success = await ref.read(authControllerProvider.notifier).signUpSeller(
                                fullName: _sellerOwnerNameController.text.trim(),
                                shopName: _sellerShopNameController.text.trim(),
                                email: _sellerEmailController.text.trim(),
                                phoneNumber: _sellerPhoneController.text.trim(),
                                address: _sellerAddressController.text.trim(),
                                city: _sellerCityController.text.trim(),
                                district: _sellerDistrict,
                                password: _sellerPasswordController.text,
                              );
                          if (success && context.mounted) {
                            _showPendingApprovalDialog(
                              title: 'Store Activated! 🎉',
                              message: 'Your Restaurant "${_sellerShopNameController.text.trim()}" in $_sellerDistrict has been successfully registered and activated. You can now sign in with your email and password!',
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Restaurant Partner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Rider Partner Registration ---
  Widget _buildRiderRegisterView(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _riderFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instant Rider Activation: Sign up and start taking delivery orders right away.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _riderNameController,
              decoration: InputDecoration(
                labelText: 'Rider Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _riderEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _riderPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
            const SizedBox(height: 10),

            // Vehicle Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicleType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: const Icon(Icons.two_wheeler_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              items: const [
                DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle / Bike')),
                DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                DropdownMenuItem(value: 'three_wheeler', child: Text('Three Wheeler (Tuk Tuk)')),
                DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                DropdownMenuItem(value: 'car', child: Text('Car / Van')),
              ],
              onChanged: (val) => setState(() => _selectedVehicleType = val ?? 'motorcycle'),
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _riderVehicleNumController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number (e.g. WP BBD-4589)',
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter vehicle number' : null,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _riderLicenseController,
              decoration: InputDecoration(
                labelText: 'Driving License No (Optional)',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _riderPasswordController,
              obscureText: _riderObscure,
              decoration: InputDecoration(
                labelText: 'Create Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_riderObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _riderObscure = !_riderObscure),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_riderFormKey.currentState?.validate() ?? false) {
                          final success = await ref.read(authControllerProvider.notifier).signUpRider(
                                fullName: _riderNameController.text.trim(),
                                email: _riderEmailController.text.trim(),
                                phoneNumber: _riderPhoneController.text.trim(),
                                vehicleType: _selectedVehicleType,
                                vehicleNumber: _riderVehicleNumController.text.trim(),
                                drivingLicenseNumber: _riderLicenseController.text.trim().isEmpty ? null : _riderLicenseController.text.trim(),
                                password: _riderPasswordController.text,
                              );
                          if (success && context.mounted) {
                            _showPendingApprovalDialog(
                              title: 'Rider Account Activated! 🛵',
                              message: 'Your rider account has been created and activated! You can now sign in with your email and password.',
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Rider Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
