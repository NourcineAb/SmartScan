import 'package:flutter/material.dart';

class AppColors {
  // ─── Light Mode Colors ───────────────────────────────────────────────────
  // Pure white background for light mode
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightCard = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF0F172A); // Navy text
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // ─── Dark Mode Colors ────────────────────────────────────────────────────
  // Charcoal & Coral theme for dark mode
  static const Color darkBg = Color(0xFF1A1A2E); // Deep charcoal
  static const Color darkSurface = Color(0xFF262641); // Medium charcoal
  static const Color darkCard = Color(0xFF2D2D44); // Lighter charcoal
  static const Color darkText = Color(0xFFFFFFFF); // White text
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Light gray
  static const Color coral = Color(0xFFFF6B6B); // Coral accent
  static const Color coralLight = Color(0xFFFF8585);
  static const Color coralDark = Color(0xFFFF4757);

  // Primary colors (now coral for dark theme)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFFA5B4FC);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFFA7F3D0);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentDark = Color(0xFFFDD34D);

  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Entity colors for highlighting
  static const Color entityDate = Color(0xFFFF6B6B);
  static const Color entityAddress = Color(0xFF4ECDC4);
  static const Color entityLocation = Color(0xFF4ECDC4);
  static const Color entityPhone = Color(0xFFFFE66D);
  static const Color entityPrice = Color(0xFF95E1D3);
  static const Color entityEmail = Color(0xFFA8DADC);
  static const Color entityUrl = Color(0xFFC7CEEA);
  static const Color entityUnknown = Color(0xFFB0B0B0);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFE0E0E0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background colors
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bgDark = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF2D2D44);

  // Category colors
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFA8DADC),
    Color(0xFFC7CEEA),
    Color(0xFFFF8B94),
    Color(0xFFFFB6B9),
    Color(0xFFFEC8D8),
    Color(0xFFFAAB78),
    Color(0xFFB5EAD7),
    Color(0xFFC7CEEA),
  ];
}
