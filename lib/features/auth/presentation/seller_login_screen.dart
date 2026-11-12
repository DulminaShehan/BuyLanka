import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/location_service.dart';
import 'package:buylanka/core/widgets/auth_feedback_banner.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

enum PartnerRole { restaurant, rider }

class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> {
  PartnerRole _selectedRole = PartnerRole.restaurant;
  int _selectedTabIndex = 0; // 0 = Sign In, 1 = Register

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

  // Sign In Controllers & State
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInObscure = true;
  bool _rememberMe = false;
  final _signInFormKey = GlobalKey<FormState>();

  // Restaurant Register Controllers & State
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

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _sellerOwnerNameController.dispose();
    _sellerShopNameController.dispose();
    _sellerEmailController.dispose();
    _sellerPhoneController.dispose();
    _sellerAddressController.dispose();
    _sellerCityController.dispose();
    _sellerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Coordinates detected: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        if (_sellerCityController.text.trim().isEmpty) {
          _sellerCityController.text = _sellerDistrict;
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to detect GPS position. Please enter address manually.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTabIndex = 0);
                  _sellerOwnerNameController.clear();
                  _sellerShopNameController.clear();
                  _sellerEmailController.clear();
                  _sellerPhoneController.clear();
                  _sellerAddressController.clear();
                  _sellerCityController.clear();
                  _sellerDistrict = 'Colombo';
                  _sellerPasswordController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Back to Sign In',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _signInEmailController.text.trim());
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reset Your Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered partner email address to receive a secure password reset link.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'partner@example.com',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          AuthFeedbackHelper.showError(context, 'Please enter a valid email address.');
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final success = await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
                        setDialogState(() => isSubmitting = false);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (success) {
                            AuthFeedbackHelper.showSuccess(
                              context,
                              'Password reset link sent! Please check your inbox 📬',
                            );
                          } else {
                            final err = ref.read(authControllerProvider).errorMessage ??
                                'Could not send reset link. Please try again.';
                            AuthFeedbackHelper.showError(context, err);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Send Link',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!(_signInFormKey.currentState?.validate() ?? false)) return;

    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text;

    bool success = false;
    if (_selectedRole == PartnerRole.restaurant) {
      success = await ref.read(authControllerProvider.notifier).signInSeller(
            email: email,
            password: password,
          );
    } else {
      success = await ref.read(authControllerProvider.notifier).signInRider(
            email: email,
            password: password,
          );
    }

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!success && mounted) {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Login failed. Please check credentials.';
      AuthFeedbackHelper.showError(context, err);
    }
  }

  Future<void> _handleRestaurantRegister() async {
    if (!(_sellerFormKey.currentState?.validate() ?? false)) return;

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

    if (success && mounted) {
      _showPendingApprovalDialog(
        title: 'Application Submitted! 🎉',
        message:
            'Your Restaurant "${_sellerShopNameController.text.trim()}" in $_sellerDistrict has been successfully registered. You can sign in once verified by BuyLanka administration.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Back button, BuyLanka logo, title, subtitle)
                _buildHeader(),

                const SizedBox(height: 22),

                // 2. Partner Selection Cards (Restaurant Partner vs Delivery Rider)
                _buildPartnerSelectionCards(),

                const SizedBox(height: 20),

                // 3. Segmented Control Tabs (Sign In vs Register)
                _buildSegmentedTabs(),

                const SizedBox(height: 14),

                // 4. Role Information Banner
                _buildInfoBanner(),

                // 5. Auth Error Message Banner
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(authState.errorMessage!),
                ],

                const SizedBox(height: 18),

                // 6. Active View (Sign In or Register)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _selectedTabIndex == 0
                      ? _buildSignInView(authState.isLoading)
                      : (_selectedRole == PartnerRole.restaurant
                          ? _buildRestaurantRegisterView(authState.isLoading)
                          : _buildRiderOnboardingView()),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header Widget ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Navigation & Logo Row
        Row(
          children: [
            // Back Button
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
            ),
            const Spacer(),

            // BuyLanka Brand Logo Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BuyLanka',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Partner Portal Title & Subtitle
        Text(
          'Partner Portal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Join as a Restaurant Partner or Delivery Rider',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // --- 2. Partner Selection Cards Widget ---
  Widget _buildPartnerSelectionCards() {
    return Row(
      children: [
        // Restaurant Partner Card
        Expanded(
          child: _buildRoleCard(
            role: PartnerRole.restaurant,
            title: 'Restaurant Partner',
            subtitle: 'Manage shop & food menu',
            icon: Icons.storefront_rounded,
          ),
        ),
        const SizedBox(width: 14),

        // Delivery Rider Card
        Expanded(
          child: _buildRoleCard(
            role: PartnerRole.rider,
            title: 'Delivery Rider',
            subtitle: 'Deliver orders & earn',
            icon: Icons.two_wheeler_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required PartnerRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedRole != role) {
            setState(() {
              _selectedRole = role;
            });
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon Container + Selection Indicator Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 24,
                    ),
                  ),

                  // Selection Indicator Badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : AppColors.border,
                        width: 1.8,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white.withValues(alpha: 0.88) : AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Segmented Control Tabs ---
  Widget _buildSegmentedTabs() {
    final registerLabel = _selectedRole == PartnerRole.restaurant ? 'Register Restaurant' : 'Rider Onboarding';

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          // Sign In Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 0) {
                  setState(() => _selectedTabIndex = 0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 0
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 17,
                        color: _selectedTabIndex == 0 ? Colors.white : AppColors.primaryDark,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w600,
                          color: _selectedTabIndex == 0 ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Register / Onboarding Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 1) {
                  setState(() => _selectedTabIndex = 1);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 1
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedRole == PartnerRole.restaurant
                            ? Icons.app_registration_rounded
                            : Icons.badge_outlined,
                        size: 17,
                        color: _selectedTabIndex == 1 ? Colors.white : AppColors.primaryDark,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          registerLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w600,
                            color: _selectedTabIndex == 1 ? Colors.white : AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Dynamic Information Banner Widget ---
  Widget _buildInfoBanner() {
    final String message;
    final IconData icon;

    if (_selectedTabIndex == 0) {
      if (_selectedRole == PartnerRole.restaurant) {
        message = 'Sign in to manage orders and menu for your restaurant.';
        icon = Icons.storefront_rounded;
      } else {
        message = 'Sign in to manage deliveries and track your earnings.';
        icon = Icons.two_wheeler_rounded;
      }
    } else {
      if (_selectedRole == PartnerRole.restaurant) {
        message = 'Register your restaurant. Applications are verified by BuyLanka operations.';
        icon = Icons.verified_user_outlined;
      } else {
        message = 'Rider accounts are verified and provisioned directly by BuyLanka Administration.';
        icon = Icons.admin_panel_settings_outlined;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Error Message Banner Widget ---
  Widget _buildErrorBanner(String errorMessage) {
    return AuthFeedbackBanner.error(
      message: errorMessage,
      onClose: () => ref.read(authControllerProvider.notifier).clearError(),
    );
  }

  // --- 6. Sign In View (Common Form for Restaurant & Rider) ---
  Widget _buildSignInView(bool isLoading) {
    final isRestaurant = _selectedRole == PartnerRole.restaurant;
    final emailLabel = isRestaurant ? 'Restaurant Email' : 'Rider Email';
    final buttonText = isRestaurant ? 'Sign In as Restaurant →' : 'Sign In as Rider →';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            Text(
              emailLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hintText: isRestaurant ? 'restaurant@buylanka.lk' : 'rider@buylanka.lk',
                prefixIcon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password Field
            Text(
              'Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _signInPasswordController,
              obscureText: _signInObscure,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _signInObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _signInObscure = !_signInObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Remember Me & Forgot Password Row
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Text(
                    'Remember me',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Main Primary Blue Gradient Action Button
            _buildPrimaryButton(
              label: buttonText,
              isLoading: isLoading,
              onPressed: isLoading ? null : _handleSignIn,
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Restaurant Register View ---
  Widget _buildRestaurantRegisterView(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _sellerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Title
            Row(
              children: [
                const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Restaurant Information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Shop Name
            Text(
              'Restaurant / Shop Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerShopNameController,
              decoration: _inputDecoration(
                hintText: 'e.g. Royal Kottu & Curry House',
                prefixIcon: Icons.storefront_outlined,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter restaurant name' : null,
            ),
            const SizedBox(height: 14),

            // Owner Full Name
            Text(
              'Owner / Manager Full Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerOwnerNameController,
              decoration: _inputDecoration(
                hintText: 'e.g. Kasun Perera',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter owner name' : null,
            ),
            const SizedBox(height: 14),

            // Business Email
            Text(
              'Business Email Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hintText: 'restaurant@example.com',
                prefixIcon: Icons.email_outlined,
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
            ),
            const SizedBox(height: 14),

            // Phone Number
            Text(
              'Contact Phone Number',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                hintText: '077 123 4567',
                prefixIcon: Icons.phone_outlined,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
            const SizedBox(height: 18),

            // Location Header & GPS Auto-fill
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Restaurant Location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _isLocating ? null : _detectCurrentLocation,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLocating)
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          _isLocating ? 'Locating...' : 'GPS Auto-fill',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Street Address
            Text(
              'Street Address / Landmark',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerAddressController,
              decoration: _inputDecoration(
                hintText: 'e.g. No. 45, Galle Road, Bambalapitiya',
                prefixIcon: Icons.pin_drop_outlined,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter street address' : null,
            ),
            const SizedBox(height: 14),

            // City and District Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City / Town',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _sellerCityController,
                        decoration: _inputDecoration(
                          hintText: 'e.g. Colombo 04',
                          prefixIcon: Icons.location_city_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // District Dropdown
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'District',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _sellerDistrict,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Select',
                          prefixIcon: Icons.map_outlined,
                        ),
                        isExpanded: true,
                        items: _districts
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _sellerDistrict = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Password
            Text(
              'Create Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellerPasswordController,
              obscureText: _sellerObscure,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hintText: 'Minimum 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _sellerObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _sellerObscure = !_sellerObscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 22),

            // Submit Button
            _buildPrimaryButton(
              label: 'Register Restaurant Partner →',
              isLoading: isLoading,
              onPressed: isLoading ? null : _handleRestaurantRegister,
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. Rider Onboarding Policy Card (Requirement 8) ---
  Widget _buildRiderOnboardingView() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            'Rider Accounts Created by Admin',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'To ensure premium safety, reliability, and Sri Lankan regulatory compliance, all BuyLanka delivery riders are onboarded through official Super Administration review.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Steps list container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to Join BuyLanka Delivery Fleet:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRiderStepItem(
                  stepNumber: '1',
                  title: 'Document Submission',
                  description: 'Valid Driving License, Revenue License, and National Identity Card (NIC).',
                ),
                const SizedBox(height: 10),
                _buildRiderStepItem(
                  stepNumber: '2',
                  title: 'Vehicle & Background Verification',
                  description: 'Physical inspection of motorcycle / vehicle and safety briefing.',
                ),
                const SizedBox(height: 10),
                _buildRiderStepItem(
                  stepNumber: '3',
                  title: 'Account Provisioning',
                  description: 'Receive your official rider login credentials and thermal delivery bag.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Contact Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Fleet Operations Desk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'riders@buylanka.lk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '011 234 5678 / 077 123 4567',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Return to Sign In Button
          _buildPrimaryButton(
            label: 'Back to Rider Sign In →',
            isLoading: false,
            onPressed: () => setState(() => _selectedTabIndex = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderStepItem({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper: Primary Button with Gradient ---
  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }

  // --- Helper: Modern Input Decoration ---
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary.withValues(alpha: 0.65),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.primary,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
    );
  }
}
