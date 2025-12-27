import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color canvasColor = Color(0xFFF7F7F7); // Off-white background
  static const Color surfaceColor = Colors.white; // Card color
  static const Color primaryColor = Colors.black; // Ink (Primary)
  static const Color secondaryColor = Color(0xFF343A40); // Ink (Secondary)
  static const Color tertiaryColor = Color(0xFF9CA3AF); // Ink (Tertiary)
  static const Color errorColor = Color(0xFFDC2626); // Error

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: primaryColor,
        error: errorColor,
        onError: Colors.white,
        // background and onBackground are deprecated in newer Flutter versions
        // but if needed for older ones:
        // background: canvasColor,
        // onBackground: primaryColor,
      ),
      // textTheme: GoogleFonts.workSansTextTheme().apply(
      //   bodyColor: primaryColor,
      //   displayColor: primaryColor,
      // ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: primaryColor),
        displayLarge: TextStyle(color: primaryColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasColor,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          // fontFamily: 'Work Sans', // Ensure font is applied
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 12px Super-Ellipse
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)), // gray-300
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: tertiaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56), // h-14 (56px)
          // textStyle: GoogleFonts.workSans(
          //   fontSize: 16,
          //   fontWeight: FontWeight.w600,
          // ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56),
          // textStyle: GoogleFonts.workSans(
          //   fontSize: 16,
          //   fontWeight: FontWeight.w600,
          // ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0.0, // Flat 2.0
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
    );
  }
}
