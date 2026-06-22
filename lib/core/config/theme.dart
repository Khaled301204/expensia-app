import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette ────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF3B82F6);   // blue-500
  static const Color primaryDark    = Color(0xFF1D4ED8);   // blue-700
  static const Color primaryLight   = Color(0xFF60A5FA);   // blue-400
  static const Color secondaryColor = Color(0xFF10B981);   // emerald-500
  static const Color accentOrange   = Color(0xFFF97316);   // orange-500
  static const Color accentPurple   = Color(0xFF8B5CF6);   // violet-500
  static const Color accentGold     = Color(0xFFF59E0B);   // amber-500
  static const Color errorColor     = Color(0xFFEF4444);   // red-500
  static const Color warningColor   = Color(0xFFFBBF24);   // amber-400
  static const Color successColor   = Color(0xFF10B981);

  // ── Dark canvas (matches screenshot) ────────────────────────────────────
  static const Color darkBg         = Color(0xFF070A14);   // near-black navy
  static const Color darkSurface    = Color(0xFF0D1117);
  static const Color darkCard       = Color(0xFF0E1220);
  static const Color darkElevated   = Color(0xFF141828);
  static const Color darkBorder     = Color(0xFF1E2540);
  static const Color darkBorderSub  = Color(0xFF252D45);
  static const Color darkTextPri    = Color(0xFFEFF2FF);
  static const Color darkTextSec    = Color(0xFF8892B0);
  static const Color darkTextMuted  = Color(0xFF4A5280);

  // ── Light canvas ─────────────────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF8FAFF);
  static const Color lightSurface   = Color(0xFFFFFFFF);
  static const Color lightCard      = Color(0xFFFFFFFF);
  static const Color lightBorder    = Color(0xFFE8EBF5);
  static const Color lightTextPri   = Color(0xFF0A0D1A);
  static const Color lightTextSec   = Color(0xFF64748B);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFF97316)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0E1220), Color(0xFF141828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows / glows ───────────────────────────────────────────────────────
  static BoxShadow blueGlow = BoxShadow(
    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
    blurRadius: 32,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  static BoxShadow subtleGlow = BoxShadow(
    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.4),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );

  // ── Inter text theme ──────────────────────────────────────────────────────
  static TextTheme _darkText() => GoogleFonts.interTextTheme(const TextTheme(
    displayLarge:   TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: darkTextPri, letterSpacing: -1.5, height: 1.0),
    displayMedium:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkTextPri, letterSpacing: -1.0, height: 1.1),
    displaySmall:   TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: darkTextPri, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkTextPri),
    titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPri),
    titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPri),
    titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPri),
    bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: darkTextPri, height: 1.6),
    bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: darkTextSec, height: 1.5),
    bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkTextMuted),
    labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPri),
    labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: darkTextSec, letterSpacing: 0.4),
  ));

  static TextTheme _lightText() => GoogleFonts.interTextTheme(const TextTheme(
    displayLarge:   TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: lightTextPri, letterSpacing: -1.5, height: 1.0),
    displayMedium:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: lightTextPri, letterSpacing: -1.0, height: 1.1),
    displaySmall:   TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: lightTextPri, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: lightTextPri),
    titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPri),
    titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPri),
    titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPri),
    bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: lightTextPri, height: 1.6),
    bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: lightTextSec, height: 1.5),
    bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightTextSec),
    labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPri),
    labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: lightTextSec, letterSpacing: 0.4),
  ));

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: darkSurface,
      onSurface: darkTextPri,
      onPrimary: Colors.white,
    ),
    textTheme: _darkText(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: darkTextPri),
      titleTextStyle: GoogleFonts.inter(
        color: darkTextPri, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3,
      ),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkTextPri,
        side: const BorderSide(color: darkBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
      prefixIconColor: darkTextSec,
      suffixIconColor: darkTextSec,
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 0),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkElevated,
      contentTextStyle: const TextStyle(color: darkTextPri),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkElevated,
      selectedColor: primaryColor,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: darkTextPri),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: darkBorder)),
      side: const BorderSide(color: darkBorder),
    ),
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: lightSurface,
    ),
    textTheme: _lightText(),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: lightTextPri),
      titleTextStyle: GoogleFonts.inter(color: lightTextPri, fontSize: 20, fontWeight: FontWeight.w700),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F4FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: lightTextSec, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 0),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
