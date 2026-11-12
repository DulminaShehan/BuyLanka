import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/widgets/auth_feedback_banner.dart';
import 'package:buylanka/features/rider/presentation/rider_application_status_screen.dart';
import 'package:buylanka/features/rider/registration/controllers/rider_registration_controller.dart';
import 'package:buylanka/features/rider/registration/models/rider_registration_model.dart';

class RiderRegistrationScreen extends ConsumerStatefulWidget {
  const RiderRegistrationScreen({super.key});

  @override
  ConsumerState<RiderRegistrationScreen> createState() =>
      _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends ConsumerState<RiderRegistrationScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Colombo');
  DateTime? _dateOfBirth = DateTime(1998, 1, 1);
  bool _obscurePassword = true;

  // Step 2 Controllers
  String _selectedVehicleType = 'motorcycle';
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();

  final List<Map<String, String>> _vehicleTypes = [
    {'type': 'motorcycle', 'label': 'Motorcycle', 'icon': '🛵'},
    {'type': 'scooter', 'label': 'Scooter', 'icon': '🛵'},
    {'type': 'three_wheeler', 'label': 'Three-Wheeler', 'icon': '🛺'},
    {'type': 'bicycle', 'label': 'Bicycle', 'icon': '🚲'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18+ years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _handleNextStep(int currentStep) {
    final controller = ref.read(riderRegistrationControllerProvider.notifier);

    if (currentStep == 0) {
      if (!(_step1FormKey.currentState?.validate() ?? false)) return;
      if (_dateOfBirth == null) {
        AuthFeedbackHelper.showError(context, 'Please select your Date of Birth.');
        return;
      }
      controller.nextStep();
    } else if (currentStep == 1) {
      if (!(_step2FormKey.currentState?.validate() ?? false)) return;
      controller.nextStep();
    } else if (currentStep == 2) {
      final regState = ref.read(riderRegistrationControllerProvider);
      if (!regState.areAllDocumentsUploaded) {
        AuthFeedbackHelper.showError(
          context,
          'Please upload all 5 required verification documents before continuing.',
        );
        return;
      }
      controller.nextStep();
    }
  }

  Future<void> _handleSubmitApplication() async {
    final regState = ref.read(riderRegistrationControllerProvider);
    final controller = ref.read(riderRegistrationControllerProvider.notifier);

    if (!regState.areAllDocumentsUploaded) {
      AuthFeedbackHelper.showError(
        context,
        'Please upload all required documents to proceed with submission.',
      );
      controller.setStep(2);
      return;
    }

    final data = RiderRegistrationData(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth ?? DateTime(2000, 1, 1),
      nicNumber: _nicController.text.trim(),
      residentialAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehicleNumber: _vehicleNumberController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehicleColor: _vehicleColorController.text.trim(),
    );

    final success = await controller.submitApplication(data);

    if (success && mounted) {
      final appResult = ref.read(riderRegistrationControllerProvider).applicationResult;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RiderApplicationStatusScreen(
            applicationId: appResult?.applicationId,
            fullName: data.fullName,
            vehicleType: data.vehicleType,
            vehicleNumber: data.vehicleNumber,
            status: 'PENDING',
            submittedAt: DateTime.now(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(riderRegistrationControllerProvider);
    final currentStep = regState.currentStep;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
            onPressed: () {
              if (currentStep > 0) {
                ref.read(riderRegistrationControllerProvider.notifier).previousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'Rider Registration',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildStepProgressBar(currentStep),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (regState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AuthFeedbackBanner(
                    type: AuthFeedbackType.error,
                    message: regState.errorMessage!,
                    onClose: () => ref
                        .read(riderRegistrationControllerProvider.notifier)
                        .setStep(currentStep),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _buildCurrentStepView(currentStep, regState),
                  ),
                ),
              ),
              _buildBottomActionBar(currentStep, regState.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressBar(int currentStep) {
    final steps = ['Personal', 'Vehicle', 'Documents', 'Review'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : (isCurrent ? AppColors.primary : AppColors.border),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              color: isCurrent ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    steps[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 2,
                      color: isCompleted ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView(int step, RiderRegistrationState regState) {
    switch (step) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Vehicle();
      case 2:
        return _buildStep3Documents(regState);
      case 3:
      default:
        return _buildStep4Review(regState);
    }
  }

  // --- STEP 1: Personal Information ---
  Widget _buildStep1Personal() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Enter your legal identity details as on your Sri Lankan NIC.',
          ),
          const SizedBox(height: 18),

          // Profile Photo Picker
          Center(child: _buildProfilePhotoPicker()),
          const SizedBox(height: 20),

          // Full Name
          _buildLabel('Full Name (as per NIC)'),
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'e.g. Kasun Chamara Perera',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 14),

          // Email
          _buildLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hint: 'e.g. kasun@gmail.com',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          _buildLabel('Account Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              hint: 'Create secure password (min 6 chars)',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 14),

          // Phone Number
          _buildLabel('Phone Number'),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              hint: 'e.g. 0771234567',
              prefixIcon: Icons.phone_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
              if (v.trim().length < 9) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Date of Birth & NIC Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Date of Birth'),
                    GestureDetector(
                      onTap: _selectDateOfBirth,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateOfBirth != null
                                  ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                                  : 'Select Date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: _dateOfBirth != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('NIC Number'),
                    TextFormField(
                      controller: _nicController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        hint: 'e.g. 200012345678 / 981234567V',
                        prefixIcon: Icons.perm_identity_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter NIC #';
                        if (v.trim().length < 9) return 'Invalid NIC';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Residential Address
          _buildLabel('Residential Address'),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDecoration(
              hint: 'e.g. No. 45, Temple Road',
              prefixIcon: Icons.home_outlined,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter your address' : null,
          ),
          const SizedBox(height: 14),

          // City
          _buildLabel('City / Area'),
          TextFormField(
            controller: _cityController,
            decoration: _inputDecoration(
              hint: 'e.g. Colombo 05 / Maharagama',
              prefixIcon: Icons.location_city_rounded,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter your city' : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoPicker() {
    final regState = ref.watch(riderRegistrationControllerProvider);
    final photo = regState.profilePhoto;

    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: photo != null
                ? Image.file(File(photo.path), fit: BoxFit.cover)
                : const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showImageSourcePicker(isProfile: true),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: Vehicle Information ---
  Widget _buildStep2Vehicle() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.two_wheeler_rounded,
            title: 'Vehicle Information',
            subtitle: 'Select your delivery vehicle type and registration details.',
          ),
          const SizedBox(height: 18),

          _buildLabel('Select Vehicle Type'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vehicleTypes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final item = _vehicleTypes[index];
              final isSelected = item['type'] == _selectedVehicleType;

              return GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = item['type']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(item['icon']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['label']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Vehicle Number
          _buildLabel('Vehicle Registration Number'),
          TextFormField(
            controller: _vehicleNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              hint: 'e.g. WP BCD-1234 or QX-5678',
              prefixIcon: Icons.pin_rounded,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter vehicle registration number' : null,
          ),
          const SizedBox(height: 14),

          // Vehicle Model
          _buildLabel('Vehicle Model / Brand'),
          TextFormField(
            controller: _vehicleModelController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'e.g. Honda CD70 / Bajaj Pulsar / TVS King',
              prefixIcon: Icons.commute_rounded,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter vehicle model' : null,
          ),
          const SizedBox(height: 14),

          // Vehicle Color
          _buildLabel('Vehicle Color'),
          TextFormField(
            controller: _vehicleColorController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'e.g. Black / Red / Blue',
              prefixIcon: Icons.color_lens_outlined,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter vehicle color' : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- STEP 3: Documents Upload ---
  Widget _buildStep3Documents(RiderRegistrationState regState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: Icons.document_scanner_rounded,
          title: 'Document Verification',
          subtitle:
              'Please upload clear, readable photos of all 5 documents. Blurry or incomplete documents may be rejected by our team.',
        ),
        const SizedBox(height: 18),

        _buildDocumentCard(
          docType: 'nic_front',
          title: 'NIC Front Image',
          description: 'Front side of your National Identity Card with clear photo and number.',
          icon: Icons.badge_rounded,
          file: regState.documents['nic_front'],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          docType: 'nic_back',
          title: 'NIC Back Image',
          description: 'Reverse side of your National Identity Card showing the barcode/address.',
          icon: Icons.badge_outlined,
          file: regState.documents['nic_back'],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          docType: 'driving_license',
          title: 'Driving Licence Image',
          description: 'Valid Sri Lankan driving licence clearly showing categories.',
          icon: Icons.card_membership_rounded,
          file: regState.documents['driving_license'],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          docType: 'vehicle_registration',
          title: 'Vehicle Registration Document',
          description: 'CR Certificate or Revenue License matching the vehicle number.',
          icon: Icons.receipt_long_rounded,
          file: regState.documents['vehicle_registration'],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          docType: 'vehicle_insurance',
          title: 'Vehicle Insurance Document',
          description: 'Valid third-party or comprehensive insurance card/policy.',
          icon: Icons.security_rounded,
          file: regState.documents['vehicle_insurance'],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String docType,
    required String title,
    required String description,
    required IconData icon,
    required XFile? file,
  }) {
    final controller = ref.read(riderRegistrationControllerProvider.notifier);
    final isUploaded = file != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUploaded ? AppColors.success : AppColors.border,
          width: isUploaded ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.successBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle_rounded : icon,
                  color: isUploaded ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isUploaded ? 'Document Attached (Tap replace to change)' : 'Required',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isUploaded ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          if (isUploaded) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 110,
                width: double.infinity,
                color: AppColors.background,
                child: Image.file(
                  File(file.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text('Document Attached', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showImageSourcePicker(docType: docType),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                  label: Text('Replace', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => controller.removeDocument(docType),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                  label: Text('Remove', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.pickDocument(docType, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: Text('Take Photo', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.pickDocument(docType, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.white),
                    label: Text('Upload File', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showImageSourcePicker({String? docType, bool isProfile = false}) {
    final controller = ref.read(riderRegistrationControllerProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isProfile ? 'Select Profile Photo' : 'Upload Document',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('Take Photo with Camera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isProfile) {
                    controller.pickProfilePhoto(ImageSource.camera);
                  } else if (docType != null) {
                    controller.pickDocument(docType, ImageSource.camera);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('Choose from Gallery / Files', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isProfile) {
                    controller.pickProfilePhoto(ImageSource.gallery);
                  } else if (docType != null) {
                    controller.pickDocument(docType, ImageSource.gallery);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 4: Review and Submit ---
  Widget _buildStep4Review(RiderRegistrationState regState) {
    final controller = ref.read(riderRegistrationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: Icons.fact_check_rounded,
          title: 'Review and Submit',
          subtitle: 'Please check your information before submitting to BuyLanka Operations.',
        ),
        const SizedBox(height: 18),

        // Personal Info Card
        _buildReviewCard(
          title: 'Personal Information',
          onEdit: () => controller.setStep(0),
          items: [
            {'label': 'Full Name', 'value': _fullNameController.text},
            {'label': 'Email', 'value': _emailController.text},
            {'label': 'Phone', 'value': _phoneController.text},
            {'label': 'NIC Number', 'value': _nicController.text},
            {
              'label': 'Date of Birth',
              'value': _dateOfBirth != null
                  ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                  : 'N/A'
            },
            {'label': 'Address', 'value': '${_addressController.text}, ${_cityController.text}'},
          ],
        ),
        const SizedBox(height: 14),

        // Vehicle Info Card
        _buildReviewCard(
          title: 'Vehicle Information',
          onEdit: () => controller.setStep(1),
          items: [
            {'label': 'Vehicle Type', 'value': _selectedVehicleType.toUpperCase()},
            {'label': 'Registration #', 'value': _vehicleNumberController.text},
            {'label': 'Model / Make', 'value': _vehicleModelController.text},
            {'label': 'Color', 'value': _vehicleColorController.text},
          ],
        ),
        const SizedBox(height: 14),

        // Documents Upload Checklist
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attached Documents (5/5)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.setStep(2),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDocCheckItem('NIC Front Image', regState.hasNicFront),
              _buildDocCheckItem('NIC Back Image', regState.hasNicBack),
              _buildDocCheckItem('Driving Licence Image', regState.hasDrivingLicense),
              _buildDocCheckItem('Vehicle Registration Document', regState.hasVehicleReg),
              _buildDocCheckItem('Vehicle Insurance Document', regState.hasVehicleInsurance),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required VoidCallback onEdit,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Edit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      item['value']!,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCheckItem(String title, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: isUploaded ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isUploaded ? AppColors.textPrimary : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Action Bar ---
  Widget _buildBottomActionBar(int currentStep, bool isLoading) {
    final isLastStep = currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(riderRegistrationControllerProvider.notifier)
                        .previousStep(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
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
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (isLastStep
                        ? _handleSubmitApplication
                        : () => _handleNextStep(currentStep)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isLastStep ? 'Submit Application →' : 'Continue to Step ${currentStep + 2} →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: AppColors.textSecondary.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 19),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}

