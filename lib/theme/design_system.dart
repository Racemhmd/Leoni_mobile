import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM — MotivUp · APEX PERFORMANCE
//
// Direction : Dark navy premium · or électrique · performance tracking
// Concept   : Strava × Bloomberg terminal — chaque point est une victoire
// Typography: Syne (display/hero) · DM Sans (body) · JetBrains Mono (data)
// Palette   : Navy profond #080E1A · Cyan #06B6D4 (système) · Or #F5C842 (récompenses)
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Brand — Cyan électrique (données / système) ───────────────────────────
  static const Color primary      = Color(0xFF06B6D4);
  static const Color primaryLight = Color(0xFF22D3EE);
  static const Color primaryDark  = Color(0xFF0891B2);

  // ── Or — Héros de la performance (points / achievements) ──────────────────
  static const Color gold      = Color(0xFFF5C842);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color goldDark  = Color(0xFFD97706);

  // ── Accent (alias cyan) ───────────────────────────────────────────────────
  static const Color accent      = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF0E2A35);
  static const Color accentDark  = Color(0xFF0369A1);

  // ── Rôles ─────────────────────────────────────────────────────────────────
  static const Color adminPrimary    = Color(0xFF0F1628);
  static const Color employeePrimary = Color(0xFF06B6D4);
  static const Color secondary       = Color(0xFF7C3AED);

  // ── Sémantique ────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF00E5A0);
  static const Color successLight = Color(0xFF0A1F18);
  static const Color error        = Color(0xFFFF3B5C);
  static const Color errorLight   = Color(0xFF2A0A12);
  static const Color warning      = Color(0xFFFF8C42);
  static const Color warningLight = Color(0xFF2A180A);
  static const Color info         = Color(0xFF06B6D4);
  static const Color infoLight    = Color(0xFF0A1E2A);

  // ── Gamification ──────────────────────────────────────────────────────────
  static const Color silver = Color(0xFF94A3B8);
  static const Color bronze = Color(0xFFCD7F32);
  static const List<Color> goldGradient   = [Color(0xFFF5C842), Color(0xFFE8A000), Color(0xFFF5C842)];
  static const List<Color> silverGradient = [Color(0xFFCBD5E1), Color(0xFF94A3B8)];
  static const List<Color> bronzeGradient = [Color(0xFFCD7F32), Color(0xFF92400E)];

  // ── Surfaces sombres — 4 niveaux de profondeur ────────────────────────────
  static const Color background       = Color(0xFF080E1A);  // Fond espace
  static const Color surface          = Color(0xFF0D1525);  // Panneau base
  static const Color surfaceElevated  = Color(0xFF131D30);  // Carte
  static const Color surfaceDark      = Color(0xFF1A2540);  // Carte élevée
  static const Color surfaceDarkCard  = Color(0xFF1E2D47);  // Élévation max
  static const Color surfaceDarkBorder = Color(0xFF243354); // Bordures accentuées

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEBF1FF);
  static const Color textSecondary = Color(0xFF7A8FAF);
  static const Color textMuted     = Color(0xFF3A4A6B);

  // Alias rétrocompatibilité
  static const Color textDark  = Color(0xFFEBF1FF);
  static const Color textLight = Color(0xFF7A8FAF);
  static const Color surfaceCard  = Color(0xFF131D30);
  static const Color cardBorder   = Color(0xFF1E2E4A);
  static const Color divider      = Color(0xFF1A2844);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

class AppTypography {
  // ── Display hero ──────────────────────────────────────────────────────────
  static TextStyle get displayHero => GoogleFonts.syne(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 0.95,
        letterSpacing: -1.8);

  // ── Headers Syne ──────────────────────────────────────────────────────────
  static TextStyle get headerLarge => GoogleFonts.syne(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5);

  static TextStyle get headerMedium => GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2);

  static TextStyle get headerSmall => GoogleFonts.syne(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  // ── Body DM Sans ──────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.6);

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.55);

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        color: AppColors.textSecondary,
        height: 1.45);

  // ── Labels / data JetBrains Mono ──────────────────────────────────────────
  static TextStyle get label => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.textSecondary);

  static TextStyle get labelBright => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Colors.white.withOpacity(0.5));

  static TextStyle get monoData => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.2);

  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5);

  // ── Button Syne ───────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.syne(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3);

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 11,
        color: AppColors.textSecondary);

  // ── Compteur or — points héros ────────────────────────────────────────────
  static TextStyle get amountLarge => GoogleFonts.syne(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: AppColors.gold,
        height: 1.0,
        letterSpacing: -2.0);

  static TextStyle get amountMedium => GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.gold,
        height: 1.0,
        letterSpacing: -1.0);
}

// ─────────────────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs  = 4;
  static const double s   = 8;
  static const double sm  = 12;
  static const double m   = 16;
  static const double ml  = 20;
  static const double l   = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: m, vertical: m);
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
}

class AppRadius {
  static const double xs   = 4;
  static const double s    = 8;
  static const double m    = 12;
  static const double l    = 16;
  static const double xl   = 20;
  static const double xxl  = 28;
  static const double full = 999;

  static BorderRadius get card        => BorderRadius.circular(xl);
  static BorderRadius get button      => BorderRadius.circular(m);
  static BorderRadius get chip        => BorderRadius.circular(full);
  static BorderRadius get input       => BorderRadius.circular(m);
  static BorderRadius get bottomSheet => const BorderRadius.only(
        topLeft: Radius.circular(xxl), topRight: Radius.circular(xxl));
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6))
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3))
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 10))
      ];

  static List<BoxShadow> get bottomNav => [
        BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4))
      ];

  // Lueur cyan — bouton principal
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8))
      ];

  // Lueur or — carte de points, badges de rang
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
            color: AppColors.gold.withOpacity(0.35),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 12)),
        BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6)),
      ];

  // Halo carte sombre
  static List<BoxShadow> get darkCard => [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 12)),
        BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> get floatingNav => [
        BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 10)),
        BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4)),
      ];
}

// ── Gradients ─────────────────────────────────────────────────────────────────

class AppGradients {
  // Cyan brand
  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandVibrant = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Or — performance / gamification
  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFF5C842), Color(0xFFE8A000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldSheen = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFF5C842), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Succès
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00B87A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chaleur / urgence
  static const LinearGradient warm = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFE85D04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Panneau sombre — fond carte principale
  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF0F1A2E), Color(0xFF0D1525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fond espace profond — hero panels
  static const LinearGradient midnight = LinearGradient(
    colors: [Color(0xFF080E1A), Color(0xFF0D1525), Color(0xFF080E1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.55, 1.0],
  );

  // Login portal
  static const LinearGradient entry = LinearGradient(
    colors: [Color(0xFF070D18), Color(0xFF0D1525), Color(0xFF080E1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  // Aurora — accents secondaires premium
  static const LinearGradient aurora = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Animation durations ───────────────────────────────────────────────────────

class AppDurations {
  static const Duration fast     = Duration(milliseconds: 150);
  static const Duration normal   = Duration(milliseconds: 300);
  static const Duration slow     = Duration(milliseconds: 500);
  static const Duration counter  = Duration(milliseconds: 1100);
  static const Duration progress = Duration(milliseconds: 1300);
}
