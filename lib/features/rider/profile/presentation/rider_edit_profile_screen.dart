import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/repositories/storage_repository.dart';

class RiderEditProfileScreen extends ConsumerStatefulWidget {
  const RiderEditProfileScreen({super.key});

  @override
  ConsumerState<RiderEditProfileScreen> createState() => _RiderEditProfileScreenState();
}

class _RiderEditProfileScreenState extends ConsumerState<RiderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _modelController;
  late TextEditingController _colorController;
  late TextEditingController _plateController;
  late TextEditingController _licenseController;

  late String _selectedVehicleType;
  XFile? _selectedAvatarFile;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  final List<Map<String, String>> _vehicleTypes = const [
    {'value': 'motorcycle', 'label': 'Motorbike / Scooter'},
    {'value': 'three_wheeler', 'label': 'Tuk-Tuk / Three Wheeler'},
    {'value': 'car', 'label': 'Car'},
    {'value': 'van', 'label': 'Delivery Van'},
    {'value': 'bicycle', 'label': 'Bicycle'},
  ];

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    final rider = authState.rider;

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _addressController = TextEditingController(text: rider?.residentialAddress ?? '');
    _modelController = TextEditingController(text: rider?.vehicleModel ?? '');
    _colorController = TextEditingController(text: rider?.vehicleColor ?? '');
    _plateController = TextEditingController(text: rider?.vehicleNumber ?? '');
    _licenseController = TextEditingController(text: rider?.drivingLicenseNumber ?? '');

    _selectedVehicleType = (rider?.vehicleType != null && rider!.vehicleType.isNotEmpty)
        ? rider.vehicleType.toLowerCase()
        : 'motorcycle';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: source == ImageSource.camera ? CameraDevice.front : CameraDevice.rear,
      );

      if (picked != null) {
        setState(() => _selectedAvatarFile = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1565C0)),
                ),
                title: Text('Take New Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1565C0)),
                ),
                title: Text('Choose from Gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    final rider = authState.rider;
    if (profile == null) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;

      // 1. Upload new photo if chosen
      if (_selectedAvatarFile != null) {
        setState(() => _isUploadingPhoto = true);
        final storage = StorageRepository();
        avatarUrl = await storage.uploadAvatar(
          file: _selectedAvatarFile!,
          userId: profile.id,
        );
        setState(() => _isUploadingPhoto = false);
      }

      // 2. Identify sensitive modifications
      final originalPlate = rider?.vehicleNumber.trim().toUpperCase() ?? '';
      final originalLicense = rider?.drivingLicenseNumber.trim().toUpperCase() ?? '';
      final originalType = rider?.vehicleType.trim().toLowerCase() ?? 'motorcycle';

      final newPlate = _plateController.text.trim().toUpperCase();
      final newLicense = _licenseController.text.trim().toUpperCase();
      final newType = _selectedVehicleType.trim().toLowerCase();

      final hasSensitiveChanges = (newPlate != originalPlate) ||
          (newLicense != originalLicense) ||
          (newType != originalType);

      // 3. Update ordinary profile fields immediately
      await ref.read(authControllerProvider.notifier).updateRiderProfileDetails(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            residentialAddress: _addressController.text.trim(),
            vehicleModel: _modelController.text.trim(),
            vehicleColor: _colorController.text.trim(),
            avatarUrl: avatarUrl,
          );

      // 4. Handle sensitive changes submission if changed
      if (hasSensitiveChanges) {
        final requested = <String, dynamic>{};
        final previous = <String, dynamic>{};

        if (newPlate != originalPlate) {
          requested['vehicle_number'] = newPlate;
          previous['vehicle_number'] = originalPlate;
        }
        if (newLicense != originalLicense) {
          requested['driving_license_number'] = newLicense;
          previous['driving_license_number'] = originalLicense;
        }
        if (newType != originalType) {
          requested['vehicle_type'] = newType;
          previous['vehicle_type'] = originalType;
        }
        if (_modelController.text.trim().isNotEmpty) {
          requested['vehicle_model'] = _modelController.text.trim();
        }
        if (_colorController.text.trim().isNotEmpty) {
          requested['vehicle_color'] = _colorController.text.trim();
        }

        await ref.read(authControllerProvider.notifier).submitRiderSensitiveChangeRequest(
              requestedChanges: requested,
              previousValues: previous,
            );

        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    'Changes Submitted',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Text(
                'Personal details were updated successfully. Your new vehicle plate, type, or license details have been sent to BuyLanka Admin for verification.\n\nYour existing approved vehicle details will remain active until approved.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF718096), height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Understood'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile updated successfully! ✨',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final rider = authState.rider;

    final hasPendingReview = rider?.profileUpdateStatus == 'pending_review';
    final isRejected = rider?.profileUpdateStatus == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF172033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Review Banner
              if (hasPendingReview) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have a vehicle/license update request pending Admin review. Your active profile continues to be shown to customers.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rejection Banner
              if (isRejected && rider?.adminRemarks != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Previous Update Rejected by Admin',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rider!.adminRemarks!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Avatar edit card
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE3F2FD),
                            border: Border.all(color: const Color(0xFF1565C0), width: 2.5),
                          ),
                          child: ClipOval(
                            child: _selectedAvatarFile != null
                                ? Image.file(
                                    File(_selectedAvatarFile!.path),
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  )
                                : (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: profile.avatarUrl!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.two_wheeler_rounded,
                                          size: 44,
                                          color: Color(0xFF1565C0),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.two_wheeler_rounded,
                                        size: 44,
                                        color: Color(0xFF1565C0),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceModal,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _showImageSourceModal,
                      child: Text(
                        'Change Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Section 1: Personal Details
              _buildSectionHeader('Personal Information', Icons.person_rounded),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name (as on NIC)',
                      hint: 'e.g. Kasun Chamara Perera',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g. 0771234567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleaned.length < 9) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Email (Read-only)
                    _buildTextField(
                      controller: TextEditingController(text: profile?.email ?? ''),
                      label: 'Registered Email',
                      hint: 'rider@buylanka.lk',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      helperText: 'Account email cannot be modified directly for security.',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Residential Address',
                      hint: 'e.g. 45/2 Galle Road, Colombo 03',
                      icon: Icons.home_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Vehicle Details
              _buildSectionHeader('Vehicle & Fleet Information', Icons.two_wheeler_rounded),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Type Dropdown
                    Text(
                      'Vehicle Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleType,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.commute_rounded, color: Color(0xFF1565C0), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F9FF),
                      ),
                      items: _vehicleTypes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t['value'],
                          child: Text(t['label']!, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVehicleType = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _modelController,
                            label: 'Vehicle Model',
                            hint: 'e.g. Honda Dio 110',
                            icon: Icons.electric_moped_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _colorController,
                            label: 'Vehicle Color',
                            hint: 'e.g. Matte Black',
                            icon: Icons.palette_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _plateController,
                      label: 'Vehicle Registration Plate',
                      hint: 'e.g. WP BCD-1234',
                      icon: Icons.confirmation_number_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Registration plate is required' : null,
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _licenseController,
                      label: 'Driving License Number',
                      hint: 'e.g. B1234567',
                      icon: Icons.assignment_ind_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Driving license is required' : null,
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Updates to Vehicle Plate, License Number, or Vehicle Type require Admin verification and approval before taking effect.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF718096),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingPhoto ? 'Uploading photo...' : 'Saving changes...',
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          'Save Profile Changes',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: readOnly ? Colors.grey[700] : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: readOnly ? Colors.grey[400] : const Color(0xFF1565C0), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF718096)),
            filled: true,
            fillColor: readOnly ? const Color(0xFFEDF2F7) : const Color(0xFFF5F9FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
