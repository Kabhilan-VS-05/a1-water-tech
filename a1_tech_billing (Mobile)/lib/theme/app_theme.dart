import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB); // Vibrant Blue // Deep Navy Blue
  static const Color accentColor = Color(0xFF2563EB); // Deep Navy Blue
  static const Color secondaryColor = Color(0xFF10B981); // Emerald Green for success/actions // Crimson Red FAB / Action
  static const Color fabColor = Color(0xFF2563EB); // Crimson Red FAB
  static const Color backgroundColorLight = Color(0xFFF3F4F6); // Light Off-White Slate
  static const Color surfaceColorLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280); // Gray 500
  static const Color dividerColorLight = Color(0xFFE5E7EB); // Gray 200
  static const Color errorColor = Color(0xFFEF4444); // Red 500

  static const Color primaryDark = Color(0xFF0B0F19); // Deep Midnight Obsidian
  static const Color surfaceDark = Color(0xFF161F30); // Rich Navy Slate Surface
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color dividerDark = Color(0xFF26334D); // Slate 700 Accent Border

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
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorLight,
      cardColor: surfaceColorLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColorLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: textPrimaryLight, letterSpacing: -1.2),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: textPrimaryLight, letterSpacing: -0.8),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: textPrimaryLight),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimaryLight, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondaryLight, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimaryLight, letterSpacing: -0.5),
        iconTheme: IconThemeData(color: textPrimaryLight),
        scrolledUnderElevation: 2,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColorLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColorLight,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColorLight,
        thickness: 1,
        space: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme);
    const darkAccent = Color(0xFF38BDF8); // Electric Sky Blue

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkAccent,
      scaffoldBackgroundColor: primaryDark,
      cardColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: Color(0xFFF43F5E),
        surface: surfaceDark,
        background: primaryDark,
        error: errorColor,
        onPrimary: Colors.black,
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
          backgroundColor: darkAccent,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.5),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF26334D), width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF26334D), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF26334D), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkAccent, width: 2),
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
        selectedItemColor: darkAccent,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF26334D),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
