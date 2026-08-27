import 'package:flutter/material.dart';

/// Matches the website's own brand palette (public/assets/css/style.css
/// :root) — navy header/text, red accent, light gray background — so the
/// app feels like the same publication, not a different product.
class AppTheme {
  AppTheme._();

  static const Color navy = Color(0xFF12233D);
  static const Color accent = Color(0xFFC8102E);
  static const Color background = Color(0xFFF5F6F8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: accent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
}
