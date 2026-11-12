import 'package:flutter/material.dart';

class AppColors {
  // Primary brand palette (Professional Blue Theme)
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color primaryVeryLight = Color(0xFFF5F9FF);
  static const Color primarySurface = Color(0xFFF5F9FF);

  // Secondary & Accents
  static const Color secondary = Color(0xFF2E7D32); // Fresh green (open status / success)
  static const Color secondaryLight = Color(0xFFE8F5E9);
  static const Color accent = Color(0xFF1565C0);

  // Status & Alerts (Updated with friendly feedback theme)
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF166534);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFFF1F2);
  
  static const Color error = Color(0xFFDC2626); // Red icon: #DC2626
  static const Color errorBg = Color(0xFFFFF1F2); // Soft red background: #FFF1F2
  static const Color errorBorder = Color(0xFFFECDD3); // Red border: #FECDD3
  static const Color errorText = Color(0xFF991B1B); // Dark readable text
  
  static const Color info = Color(0xFF1565C0); // Blue icon: #1565C0
  static const Color infoBg = Color(0xFFE3F2FD); // Light blue background: #E3F2FD
  static const Color infoBorder = Color(0xFFBFDBFE); // Light blue border
  static const Color infoText = Color(0xFF0D47A1); // Dark readable blue text

  // Neutral tones
  static const Color background = Color(0xFFF5F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD9E2EC);
  static const Color borderDark = Color(0xFFCBD5E1);

  // Typography
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFF718096);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Order status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF1565C0);
  static const Color statusPreparing = Color(0xFF8B5CF6);
  static const Color statusReady = Color(0xFF10B981);
  static const Color statusDelivered = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFFEF4444);
}
