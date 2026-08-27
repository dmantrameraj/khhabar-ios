import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_node.dart';
import '../../widgets/news_card.dart';
import 'category_detail_screen.dart';

final categoriesProvider = FutureProvider<List<CategoryNode>>((ref) {
  return ref.watch(newsRepositoryProvider).getCategories();
});

/// Categories are loaded dynamically from the live API, never hardcoded —
/// whatever exists in Website Settings → Categories on khhabar.com is
/// exactly what shows here.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        data: (list) {
          if (list.isEmpty) return const EmptyStateView(message: 'No categories yet.');
          return RefreshIndicator(
            onRefresh: () => ref.refresh(categoriesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) => _CategoryGroup(category: list[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(categoriesProvider)),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final CategoryNode category;

  const _CategoryGroup({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CategoryDetailScreen(slug: category.slug, name: category.name)),
            ),
          ),
          if (category.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: category.children
                    .map(
                      (c) => ActionChip(
                        label: Text(c.name),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CategoryDetailScreen(slug: c.slug, name: c.name)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
