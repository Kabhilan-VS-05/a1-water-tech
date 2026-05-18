import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F172A); // Slate 900
  static const Color accentColor = Color(0xFF3B82F6); // Blue 500
  static const Color secondaryColor = Color(0xFF10B981); // Emerald 500
  static const Color backgroundColorLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColorLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color dividerColorLight = Color(0xFFE2E8F0); // Slate 200
  static const Color errorColor = Color(0xFFEF4444); // Red 500

  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color dividerDark = Color(0xFF334155); // Slate 700

  static const MaterialColor slate = MaterialColor(
    0xFF64748B,
    <int, Color>{
      50: Color(0xFFF8FAFC),
      100: Color(0xFFF1F5F9),
      200: Color(0xFFE2E8F0),
      300: Color(0xFFCBD5E1),
      400: Color(0xFF94A3B8),
      500: Color(0xFF64748B),
      600: Color(0xFF475569),
      700: Color(0xFF334155),
      800: Color(0xFF1E293B),
      900: Color(0xFF0F172A),
    },
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: backgroundColorLight,
      cardColor: surfaceColorLight,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: secondaryColor,
        surface: surfaceColorLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -1),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -0.5),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryLight),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimaryLight),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondaryLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimaryLight, letterSpacing: -0.5),
        iconTheme: IconThemeData(color: textPrimaryLight),
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: accentColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColorLight,
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColorLight,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: primaryDark,
      cardColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        background: primaryDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -1),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -0.5),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: textPrimaryDark),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimaryDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondaryDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimaryDark, letterSpacing: -0.5),
        iconTheme: IconThemeData(color: textPrimaryDark),
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 1,
      ),
    );
  }
}
