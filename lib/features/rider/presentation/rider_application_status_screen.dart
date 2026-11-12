import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/rider/presentation/rider_main_nav_screen.dart';

class RiderApplicationStatusScreen extends ConsumerStatefulWidget {
  final String? applicationId;
  final String? fullName;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? status;
  final DateTime? submittedAt;
  final String? rejectionReason;

  const RiderApplicationStatusScreen({
    super.key,
    this.applicationId,
    this.fullName,
    this.vehicleType,
    this.vehicleNumber,
    this.status,
    this.submittedAt,
    this.rejectionReason,
  });

  @override
  ConsumerState<RiderApplicationStatusScreen> createState() =>
      _RiderApplicationStatusScreenState();
}

class _RiderApplicationStatusScreenState
    extends ConsumerState<RiderApplicationStatusScreen> {
  bool _isRefreshing = false;

  Future<void> _checkStatus() async {
    setState(() => _isRefreshing = true);
    try {
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;

      final authState = ref.read(authControllerProvider);
      if (authState.rider?.isApproved == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RiderMainNavScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Application is still under review. Thank you for your patience!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final rider = authState.rider;
    final profile = authState.profile;

    final displayAppId = widget.applicationId ??
        'APP-${(profile?.id ?? rider?.id ?? 'RIDER').substring(0, 8).toUpperCase()}';
    final displayName = widget.fullName ?? profile?.fullName ?? 'Delivery Partner';
    final displayVehicle = widget.vehicleType ?? rider?.vehicleTypeDisplay ?? 'Motorcycle';
    final displayRegNo = widget.vehicleNumber ?? rider?.vehicleNumber ?? 'Pending';
    final currentStatus = widget.status ??
        (rider?.verificationStatus.toUpperCase() ?? 'PENDING');
    final submittedDateStr = widget.submittedAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(widget.submittedAt!)
        : DateFormat('MMM dd, yyyy').format(DateTime.now());

    final isRejected = currentStatus == 'REJECTED';
    final isResubmission = currentStatus == 'RESUBMISSION_REQUIRED';

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
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          title: Text(
            'Application Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              tooltip: 'Sign Out',
              onPressed: _handleSignOut,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Status Header Banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRejected
                          ? AppColors.danger.withValues(alpha: 0.3)
                          : isResubmission
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status Icon Badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isRejected
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : isResubmission
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isRejected
                                ? Icons.cancel_outlined
                                : isResubmission
                                    ? Icons.error_outline_rounded
                                    : Icons.hourglass_top_rounded,
                            size: 38,
                            color: isRejected
                                ? AppColors.danger
                                : isResubmission
                                    ? AppColors.warning
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRejected
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : isResubmission
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isRejected
                              ? 'REJECTED'
                              : isResubmission
                                  ? 'RESUBMISSION REQUIRED'
                                  : 'PENDING APPROVAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isRejected
                                ? AppColors.danger
                                : isResubmission
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFFD97706),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Main Title
                      Text(
                        'Your rider application has been submitted successfully.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Your application is waiting for Admin approval. Our BuyLanka team will review your identity and vehicle documents shortly.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Visual Status Timeline
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Progress',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTimelineTile(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        title: 'Application Submitted',
                        subtitle: submittedDateStr,
                        isDone: true,
                        showLine: true,
                      ),
                      _buildTimelineTile(
                        icon: Icons.search_rounded,
                        color: AppColors.primary,
                        title: 'Documents Under Review',
                        subtitle: 'Our operations team is currently reviewing your documents.',
                        isDone: true,
                        isActive: true,
                        showLine: true,
                      ),
                      _buildTimelineTile(
                        icon: Icons.verified_user_outlined,
                        color: AppColors.textSecondary,
                        title: 'Admin Verification & Approval',
                        subtitle: 'Compliance and criminal background check.',
                        isDone: false,
                        showLine: true,
                      ),
                      _buildTimelineTile(
                        icon: Icons.delivery_dining_rounded,
                        color: AppColors.textSecondary,
                        title: 'Account Activated',
                        subtitle: 'Receive orders and start earning with BuyLanka.',
                        isDone: false,
                        showLine: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Application Summary Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Summary',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSummaryRow('Application ID', displayAppId),
                      const Divider(height: 20),
                      _buildSummaryRow('Applicant Name', displayName),
                      const Divider(height: 20),
                      _buildSummaryRow('Vehicle Type', displayVehicle),
                      const Divider(height: 20),
                      _buildSummaryRow('Vehicle Number', displayRegNo),
                      const Divider(height: 20),
                      _buildSummaryRow('Documents Status', '5/5 Uploaded (Pending Review)'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Action Buttons
                SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _checkStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isRefreshing ? 'Checking Status...' : 'Check Latest Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Return to Portal Button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    'Return to Partner Portal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isActive = false,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone
                    ? color.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? color : AppColors.border,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 16,
                  color: isDone ? color : Colors.grey,
                ),
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 34,
                color: isDone ? color.withValues(alpha: 0.4) : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                    color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

