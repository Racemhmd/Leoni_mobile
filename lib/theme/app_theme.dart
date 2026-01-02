import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF003366); // LTG-style Dark Blue
  static const Color secondaryBlue = Color(0xFF0056b3); // Brighter Blue for interactions
  static const Color statusGreen = Color(0xFF28A745); // Enterprise Green
  static const Color statusRed = Color(0xFFDC3545); // Enterprise Red
  static const Color backgroundLight = Color(0xFFF4F6F9); // Neutral Light Grey
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF212529);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryBlue,
        background: backgroundLight,
        surface: surfaceWhite,
        error: statusRed,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.robotoTextTheme().copyWith( // Roboto is very standard/enterprise
        displayLarge: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: const TextStyle(color: textDark),
         bodyMedium: const TextStyle(color: Color(0xFF495057)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false, // Left aligned is more enterprise
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 1, // Subtle
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Straighter edges
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.grey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      iconTheme: const IconThemeData(color: primaryBlue),
    );
  }
}
