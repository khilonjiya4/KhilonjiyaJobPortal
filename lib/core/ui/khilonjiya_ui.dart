import 'package:flutter/material.dart';

class KhilonjiyaUI {
  // ============================================================
  // COLORS (NAUKRI STYLE – SOFT & LIGHT)
  // ============================================================

  static const Color bg = Color(0xFFF8FAFC);          // lighter background
  static const Color card = Colors.white;
  static const Color border = Color(0xFFF1F5F9);      // softer border
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF64748B);
  static const Color lightMuted = Color(0xFF94A3B8);
  static const Color primary = Color(0xFF2563EB);

  // Light orange tag colors
  static const Color tagBg = Color(0xFFFFF4E6);
  static const Color tagBorder = Color(0xFFFFE2C7);
  static const Color tagText = Color(0xFFB45309);

  // ============================================================
  // RADIUS (SMALLER – CLEAN)
  // ============================================================

  static BorderRadius r10 = BorderRadius.circular(10);
  static BorderRadius r12 = BorderRadius.circular(12);
  static BorderRadius r14 = BorderRadius.circular(14);

  // ============================================================
  // TEXT STYLES (SLIM HIERARCHY)
  // ============================================================

  static const TextStyle h1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,   // slim
    color: text,
    height: 1.2,
  );

  static const TextStyle company = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: muted,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,   // lighter
    color: muted,
    height: 1.3,
  );

  static const TextStyle sub = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: lightMuted,
    height: 1.2,
  );

  static const TextStyle link = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: primary,
    height: 1.2,
  );

  // ============================================================
  // CARD DECORATION (FLAT – NO HEAVY SHADOW)
  // ============================================================

  static BoxDecoration cardDecoration({
    double radius = 12,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  // ============================================================
  // TAG STYLE (LIGHT ORANGE – SLIM)
  // ============================================================

  static BoxDecoration tagDecoration() {
    return BoxDecoration(
      color: tagBg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tagBorder),
    );
  }

  static const TextStyle tagTextStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: tagText,
  );

  // ============================================================
  // THEME (MINIMAL)
  // ============================================================

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: "Inter",
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
        primary: primary,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}