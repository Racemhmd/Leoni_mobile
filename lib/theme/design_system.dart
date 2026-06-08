import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Core Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryDark = Color(0xFF1E40AF);

  // ── Role-specific ────────────────────────────────────────────────────────────
  static const Color adminPrimary = Color(0xFF1E3A8A);
  static const Color employeePrimary = Color(0xFF1A56DB);
  static const Color secondary = Color(0xFF7C3AED);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEDE9FE);

  // ── Gamification ─────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const List<Color> goldGradient = [Color(0xFFFDB931), Color(0xFFFFD700), Color(0xFFFDB931)];
  static const List<Color> silverGradient = [Color(0xFFE0E0E0), Color(0xFFBDBDBD)];
  static const List<Color> bronzeGradient = [Color(0xFFCD7F32), Color(0xFFA0522D)];

  // ── Neutrals ─────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  // Aliases kept for backward-compat with existing screens
  static const Color textDark = Color(0xFF111827);
  static const Color textLight = Color(0xFF6B7280);

  // Surface variants
  static const Color surfaceCard = Color(0xFFF8FAFF);
  static const Color cardBorder = Color(0xFFF1F5F9);
}

class AppTypography {
  static TextStyle get headerLarge => GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  static TextStyle get headerMedium => GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get headerSmall => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, color: AppColors.textPrimary, height: 1.5);

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, color: AppColors.textPrimary, height: 1.5);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, color: AppColors.textSecondary, height: 1.4);

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textSecondary);

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2);

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, color: AppColors.textSecondary);

  static TextStyle get amountLarge => GoogleFonts.inter(
        fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0);
}

class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double sm = 12;
  static const double m = 16;
  static const double ml = 20;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: m, vertical: m);
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
}

class AppRadius {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get button => BorderRadius.circular(m);
  static BorderRadius get chip => BorderRadius.circular(full);
  static BorderRadius get input => BorderRadius.circular(m);
  static BorderRadius get bottomSheet => const BorderRadius.only(
        topLeft: Radius.circular(xxl), topRight: Radius.circular(xxl));
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4))
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6))
      ];

  static List<BoxShadow> get bottomNav => [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4))
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8))
      ];

  static List<BoxShadow> get floatingNav => [
        BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 8)),
        BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4)),
      ];
}

// ── Gradients ────────────────────────────────────────────────────────────────

class AppGradients {
  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandVibrant = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warm = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFFDB931), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Animation durations ───────────────────────────────────────────────────────

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration counter = Duration(milliseconds: 900);
  static const Duration progress = Duration(milliseconds: 1100);
}
