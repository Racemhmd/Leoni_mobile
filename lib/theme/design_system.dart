import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Core
  static const Color primary = Color(0xFF003366); // Deep Navy
  static const Color secondary = Color(0xFF0056b3); // Bright Blue

  // Role Specific
  static const Color adminPrimary = Color(0xFF1A1A2E); // Dark Slate
  static const Color employeePrimary = Color(0xFF1565C0); // Vibrant Blue

  // Functional
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Rewards / Gamification
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  
  static const List<Color> goldGradient = [Color(0xFFFDB931), Color(0xFFFFD700), Color(0xFFFDB931)];
  static const List<Color> silverGradient = [Color(0xFFE0E0E0), Color(0xFFBDBDBD)];
  static const List<Color> bronzeGradient = [Color(0xFFCD7F32), Color(0xFFA0522D)];

  // Neutrals
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
}

class AppTypography {
  // Headings (Outfit - Modern, Bold)
  static TextStyle get headerLarge => GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark,
  );

  static TextStyle get headerMedium => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark,
  );
  
  static TextStyle get headerSmall => GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark,
  );

  // Body (Inter - Clean, Legible)
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, color: AppColors.textDark,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, color: AppColors.textDark,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, color: AppColors.textLight,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: AppColors.textLight,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  static const EdgeInsets pagePadding = EdgeInsets.all(m);
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
