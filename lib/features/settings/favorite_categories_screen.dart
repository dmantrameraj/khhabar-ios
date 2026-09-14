import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/user_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/news_card.dart';
import '../home/home_screen.dart' show topCategoriesProvider;

/// "मेरा पसंदीदा विषय" — pick which categories matter most; picks sort
/// first in Home's swipeable tabs (see home_screen.dart), so this is
/// real, immediate personalization rather than a setting with no effect.
class FavoriteCategoriesScreen extends ConsumerWidget {
  const FavoriteCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(topCategoriesProvider);
    final favorites = ref.watch(favoriteCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('मेरा पसंदीदा विषय')),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? const EmptyStateView(message: 'कोई विषय उपलब्ध नहीं है।')
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final selected = favorites.contains(c.slug);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => ref.read(favoriteCategoriesProvider.notifier).toggle(c.slug),
                    title: Text(c.name),
                    activeColor: AppTheme.accent,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(topCategoriesProvider)),
      ),
    );
  }
}
