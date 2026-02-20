import 'package:flutter/material.dart';

class KhilonjiyaUI {
  static const Color bg = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color primary = Color(0xFF2563EB);

  static BorderRadius r12 = BorderRadius.circular(12);
  static BorderRadius r16 = BorderRadius.circular(16);
  static BorderRadius r20 = BorderRadius.circular(20);

  static const TextStyle h1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.2,
  );

  static const TextStyle hTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: text,
    height: 1.35,
  );

  static const TextStyle sub = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: muted,
    height: 1.25,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: muted,
    height: 1.2,
  );

  static const TextStyle link = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: primary,
    height: 1.2,
  );

  // Required for job_card_widget

  static const TextStyle company = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: muted,
    height: 1.2,
  );

  static BoxDecoration tagDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
    );
  }

  static const TextStyle tagTextStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF334155),
  );

  static BoxDecoration cardDecoration({
    double? radius,
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius ?? 16),
      border: Border.all(color: border),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    );
  }

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