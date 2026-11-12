import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/widgets/auth_feedback_banner.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/seller_login_screen.dart';

class CustomerAuthScreen extends ConsumerStatefulWidget {
  const CustomerAuthScreen({super.key});

  @override
  ConsumerState<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends ConsumerState<CustomerAuthScreen> {
  // 0 = Sign In, 1 = Register
  int _selectedTabIndex = 0;

  // Sign In Controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInObscure = true;
  bool _rememberMe = false;

  // Register Controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  bool _signUpObscure = true;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Brand gradient colors matching the design
  static const Color _brandBlueStart = Color(0xFF005CE0);
  static const Color _brandBlueEnd = Color(0xFF0044B0);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _inputBorder = Color(0xFFDCE4F0);

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _signInEmailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Your Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your registered email address and we will send you a password recovery link.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Please enter a valid email address'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_brandBlueStart, _brandBlueEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x35005CE0),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() ?? false) {
                                setModalState(() => isSubmitting = true);
                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .sendPasswordReset(
                                      resetEmailController.text.trim(),
                                    );
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  if (success) {
                                    AuthFeedbackHelper.showSuccess(
                                      context,
                                      'Password reset link sent! Please check your inbox 📬',
                                    );
                                  } else {
                                    final err = ref.read(authControllerProvider).errorMessage ??
                                        'Could not send reset link. Please check the email.';
                                    AuthFeedbackHelper.showError(
                                      context,
                                      err,
                                    );
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Send Reset Link',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: _textMuted,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: _textDark,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inputBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brandBlueStart, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
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
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Hero Illustration Banner (Sky, Rider with BuyLanka Box, Skyline, Lotus Tower, Logo)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 494 / 316,
                    child: Image.asset(
                      'assets/images/auth_header.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.0,
                      child: Text('BuyLanka'),
                    ),
                  ),
                ],
              ),

              // Main Form Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Control Tabs (Sign In / Register)
                    Container(
                      height: 52,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _inputBorder, width: 1.2),
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
                                          colors: [_brandBlueStart, _brandBlueEnd],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: _selectedTabIndex == 0
                                      ? null
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedTabIndex == 0
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x35005CE0),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 20,
                                        color: _selectedTabIndex == 0
                                            ? Colors.white
                                            : _textDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sign In',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedTabIndex == 0
                                              ? Colors.white
                                              : _textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Register Tab
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
                                          colors: [_brandBlueStart, _brandBlueEnd],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: _selectedTabIndex == 1
                                      ? null
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedTabIndex == 1
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x35005CE0),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_outlined,
                                        size: 20,
                                        color: _selectedTabIndex == 1
                                            ? Colors.white
                                            : _textDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Register',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedTabIndex == 1
                                              ? Colors.white
                                              : _textDark,
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
                    ),

                    // Error Message Banner (if any)
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      AuthFeedbackBanner.error(
                        message: authState.errorMessage!,
                        onClose: () => ref.read(authControllerProvider.notifier).clearError(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Active Tab Form
                    if (_selectedTabIndex == 0)
                      _buildSignInForm(authState.isLoading)
                    else
                      _buildRegisterForm(authState.isLoading),

                    const SizedBox(height: 20),

                    // Divider: --- OR ---
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: _inputBorder,
                            thickness: 1.2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: _inputBorder,
                            thickness: 1.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Restaurant & Rider Partner Portal Outlined Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SellerLoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _brandBlueStart,
                        side: const BorderSide(
                          color: _brandBlueStart,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 22,
                            color: _brandBlueStart,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Restaurant & Rider Partner Portal',
                            style: GoogleFonts.plusJakartaSans(
                              color: _brandBlueStart,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: _brandBlueStart,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Decorative Wave Accent
              AspectRatio(
                aspectRatio: 494 / 104,
                child: Image.asset(
                  'assets/images/auth_bottom_waves.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== SIGN IN FORM =====================
  Widget _buildSignInForm(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Address Label
          Text(
            'Email Address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Email Input Field
          TextFormField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Please enter a valid email address'
                : null,
          ),
          const SizedBox(height: 18),

          // Password Label
          Text(
            'Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Password Input Field
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _signInObscure,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _signInObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _signInObscure = !_signInObscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 12),

          // Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me Checkbox
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() => _rememberMe = val ?? false);
                          },
                          activeColor: _brandBlueStart,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Forgot Password Link
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _brandBlueStart,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Sign In as Customer Primary Button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_brandBlueStart, _brandBlueEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38005CE0),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_signInFormKey.currentState?.validate() ?? false) {
                        ref
                            .read(authControllerProvider.notifier)
                            .signInCustomer(
                              email: _signInEmailController.text.trim(),
                              password: _signInPasswordController.text,
                            );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sign In as Customer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== REGISTER FORM =====================
  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          Text(
            'Full Name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpNameController,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your full name'
                : null,
          ),
          const SizedBox(height: 16),

          // Email Address
          Text(
            'Email Address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Please enter a valid email address'
                : null,
          ),
          const SizedBox(height: 16),

          // Phone Number
          Text(
            'Phone Number',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: '077 123 4567',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Password
          Text(
            'Create Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _signUpObscure,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'At least 6 characters',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _signUpObscure = !_signUpObscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 24),

          // Create Customer Account Primary Button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_brandBlueStart, _brandBlueEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38005CE0),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_signUpFormKey.currentState?.validate() ?? false) {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signUpCustomer(
                              fullName: _signUpNameController.text.trim(),
                              email: _signUpEmailController.text.trim(),
                              password: _signUpPasswordController.text,
                              phoneNumber: _signUpPhoneController.text.trim(),
                            );
                        if (success && mounted) {
                          AuthFeedbackHelper.showSuccess(
                            context,
                            'Account created successfully! Welcome to BuyLanka 🎉',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Customer Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
