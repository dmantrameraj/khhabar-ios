import 'package:flutter/material.dart';

/// Matches the website's own brand palette (public/assets/css/style.css
/// :root) — navy header/text, red accent, light gray background — so the
/// app feels like the same publication, not a different product.
class AppTheme {
  AppTheme._();

  static const Color navy = Color(0xFF12233D);
  static const Color accent = Color(0xFFC8102E);
  static const Color background = Color(0xFFF5F6F8);

  // Dark-mode surface colors — a near-black navy-tinted background rather
  // than pure black (easier on the eyes, still reads as "the same navy
  // brand" instead of a generic Material dark theme) and a slightly
  // lighter card surface so cards stay visually distinct from the
  // scaffold behind them.
  static const Color darkBackground = Color(0xFF0B1420);
  static const Color darkSurface = Color(0xFF16223A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
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

  // Most screens never hardcode a background/surface color — they inherit
  // Scaffold/Card/AppBar defaults from the active ThemeData, so this one
  // definition covers the large majority of the app automatically. A
  // handful of widgets DO hardcode a light-only color directly (mostly
  // `Colors.white` text meant to sit on a colored/image background, which
  // stays correct in both themes since it's never on the scaffold
  // background) — those aren't touched by this pass.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: Colors.white,
          secondary: accent,
          brightness: Brightness.dark,
          surface: darkSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: darkSurface,
        ),
        dividerColor: Colors.white24,
      );
}
