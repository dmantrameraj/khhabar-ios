import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/breaking_item.dart';
import '../../widgets/news_card.dart';
import '../article/article_screen.dart';

final _breakingNewsProvider = FutureProvider<List<BreakingItem>>((ref) {
  return ref.watch(newsRepositoryProvider).getBreaking();
});

/// Opened from the bell icon on Home — today this is Breaking News reused
/// as an "Alerts" feed rather than a real notification-history inbox
/// (OneSignal doesn't hand the app a delivery history, and building one
/// would need new backend work). GET /news/breaking is a lightweight
/// title+slug ticker query, so rows here are plain title tiles rather
/// than full NewsListTile cards — see PushService for actual push
/// delivery, which is unrelated to this screen.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_breakingNewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('अलर्ट')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_breakingNewsProvider.future),
        child: async.when(
          data: (items) => items.isEmpty
              ? const EmptyStateView(message: 'No breaking news right now.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      leading: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: item.slug))),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(_breakingNewsProvider)),
        ),
      ),
    );
  }
}
