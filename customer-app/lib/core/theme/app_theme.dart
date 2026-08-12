import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: const Color(0xFFF8FAFC),
        surface: Colors.white,
        text: const Color(0xFF0F172A),
        border: const Color(0xFFE2E8F0),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: const Color(0xFF0B1220),
        surface: const Color(0xFF1A2436),
        text: const Color(0xFFF1F5F9),
        border: const Color(0xFF2A3750),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color text,
    required Color border,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        brightness: brightness,
      ).copyWith(surface: surface),
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: border,
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
