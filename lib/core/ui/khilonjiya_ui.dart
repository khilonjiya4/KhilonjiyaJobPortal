import 'package:flutter/material.dart';

class KhilonjiyaUI {
  // ================= COLORS =================

  static const Color bg = Color(0xFFF8F9FB);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFF1F3F6);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color primary = Color(0xFF2563EB);

  // Modern soft tag (startup style)
  static const Color tagBg = Color(0xFFFFF3E8);
  static const Color tagText = Color(0xFFEA580C);

  // ================= RADIUS =================

  static BorderRadius r8 = BorderRadius.circular(8);
  static BorderRadius r10 = BorderRadius.circular(10);
  static BorderRadius r12 = BorderRadius.circular(12);

  // ================= TYPOGRAPHY =================

  // Job Title (primary attention)
  static const TextStyle jobTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // Company name
  static const TextStyle company = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: text,
    height: 1.2,
  );

  // Detail rows (location, salary, etc.)
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: text,
    height: 1.3,
  );

  // Muted metadata
  static const TextStyle sub = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: muted,
    height: 1.2,
  );

  // Tag text
  static const TextStyle tagTextStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: tagText,
  );

  // ================= DECORATIONS =================

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: card,
      borderRadius: r12,
      border: Border.all(color: border, width: 0.6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration tagDecoration() {
    return BoxDecoration(
      color: tagBg,
      borderRadius: BorderRadius.circular(20),
    );
  }

  // ================= THEME =================

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