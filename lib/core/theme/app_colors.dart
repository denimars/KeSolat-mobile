import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Color Scheme
  static const Color primary = Color(0xFF0C577D);
  static const Color secondary = Color(0xFF00A86B);
  static const Color accent = Color(0xFFFFB84D);

  // Button Colors
  static const Color primaryButton = Color(0xFF0C577D);
  static const Color secondaryButton = Color(0xFF0E6B99);
  static const Color disabledButton = Color(0xFFB0BEC5);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF0A3D56);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF1A1A1A);

  // Status & State Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Prayer State Colors
  static const Color activePrayer = Color(0xFF00A86B);
  static const Color upcomingPrayer = Color(0xFFFFB84D);
  static const Color passedPrayer = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C577D), Color(0xFF0E6B99)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB84D), Color(0xFFFFA726)],
  );

  // Additional UI Colors
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x1A000000);
}
