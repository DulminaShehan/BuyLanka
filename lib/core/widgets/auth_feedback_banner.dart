import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buylanka/core/constants/app_colors.dart';

enum AuthFeedbackType { error, success, info }

/// Modern, friendly inline feedback banner adhering to BuyLanka design specifications.
class AuthFeedbackBanner extends StatelessWidget {
  final String message;
  final AuthFeedbackType type;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? margin;

  const AuthFeedbackBanner({
    super.key,
    required this.message,
    this.type = AuthFeedbackType.error,
    this.onClose,
    this.margin,
  });

  const AuthFeedbackBanner.error({
    super.key,
    required this.message,
    this.onClose,
    this.margin,
  }) : type = AuthFeedbackType.error;

  const AuthFeedbackBanner.success({
    super.key,
    required this.message,
    this.onClose,
    this.margin,
  }) : type = AuthFeedbackType.success;

  const AuthFeedbackBanner.info({
    super.key,
    required this.message,
    this.onClose,
    this.margin,
  }) : type = AuthFeedbackType.info;

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, iconColor, textColor, icon) = switch (type) {
      AuthFeedbackType.error => (
          AppColors.errorBg, // #FFF1F2
          AppColors.errorBorder, // #FECDD3
          AppColors.error, // #DC2626
          AppColors.errorText, // #991B1B
          Icons.error_outline_rounded,
        ),
      AuthFeedbackType.success => (
          AppColors.successBg, // #F0FDF4
          AppColors.successBorder, // #BBF7D0
          AppColors.success, // #16A34A
          AppColors.successText, // #166534
          Icons.check_circle_outline_rounded,
        ),
      AuthFeedbackType.info => (
          AppColors.infoBg, // #E3F2FD
          AppColors.infoBorder, // #BFDBFE
          AppColors.info, // #1565C0
          AppColors.infoText, // #0D47A1
          Icons.info_outline_rounded,
        ),
    };

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: iconColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper to display modern floating snackbars for success, error, or info.
class AuthFeedbackHelper {
  /// Shows a modern floating error SnackBar (#FFF1F2 background, #FECDD3 border, #DC2626 icon)
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.errorText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorBg,
        elevation: 2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.errorBorder, width: 1.2),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a modern floating success SnackBar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.successText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.successBg,
        elevation: 2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.successBorder, width: 1.2),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a modern floating info SnackBar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.infoText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.infoBg,
        elevation: 2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.infoBorder, width: 1.2),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

