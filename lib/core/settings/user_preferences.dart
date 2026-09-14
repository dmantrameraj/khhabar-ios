import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plain-text local prefs (theme, article text size, favorite categories)
/// — nothing sensitive, unlike the auth token which stays in
/// `flutter_secure_storage` (see TokenStorage). Overridden in main() with
/// a real, already-`await`ed `SharedPreferences.getInstance()` instance
/// before `runApp` — every provider below assumes that override is in
/// place and reads/writes synchronously against it.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main() before runApp');
});

const _themeModeKey = 'khhabar_theme_mode';
const _fontScaleKey = 'khhabar_article_font_scale';
const _favoriteCategoriesKey = 'khhabar_favorite_categories';

/// Light / Dark / System — persisted so the choice survives an app
/// restart. Read by `KhhabarApp`'s `MaterialApp(themeMode: ...)`.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_themeModeKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_themeModeKey, mode.name);
  }
}

/// Article body text size — three fixed steps rather than a free slider,
/// simpler to reason about and matches how most news apps expose this.
/// `size` is the base `fontSize` fed to `ArticleScreen`'s `Html` widget.
enum ArticleFontScale {
  small(label: 'छोटा', size: 13),
  medium(label: 'मध्यम', size: 15),
  large(label: 'बड़ा', size: 18);

  final String label;
  final double size;

  const ArticleFontScale({required this.label, required this.size});
}

final articleFontScaleProvider = NotifierProvider<ArticleFontScaleNotifier, ArticleFontScale>(
  ArticleFontScaleNotifier.new,
);

class ArticleFontScaleNotifier extends Notifier<ArticleFontScale> {
  @override
  ArticleFontScale build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_fontScaleKey);
    return ArticleFontScale.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => ArticleFontScale.medium,
    );
  }

  void set(ArticleFontScale scale) {
    state = scale;
    ref.read(sharedPreferencesProvider).setString(_fontScaleKey, scale.name);
  }
}

/// Category slugs the reader has marked as favorites on the "मेरा
/// पसंदीदा विषय" screen — genuinely affects the app, not just a saved
/// preference with no visible effect: Home's swipeable category tabs
/// (see `home_screen.dart`) sort favorited categories first (after
/// Home itself), so picking favorites is real, immediate personalization
/// rather than a dead-end settings toggle.
final favoriteCategoriesProvider = NotifierProvider<FavoriteCategoriesNotifier, Set<String>>(
  FavoriteCategoriesNotifier.new,
);

class FavoriteCategoriesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final saved = ref.read(sharedPreferencesProvider).getStringList(_favoriteCategoriesKey);
    return saved?.toSet() ?? <String>{};
  }

  void toggle(String slug) {
    final next = Set<String>.from(state);
    if (!next.remove(slug)) {
      next.add(slug);
    }
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_favoriteCategoriesKey, next.toList());
  }
}
