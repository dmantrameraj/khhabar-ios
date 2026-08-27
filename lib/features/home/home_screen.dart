import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/home_feed.dart';
import '../../widgets/news_card.dart';
import '../article/article_screen.dart';
import '../categories/category_detail_screen.dart';

final homeFeedProvider = FutureProvider<HomeFeed>((ref) {
  return ref.watch(newsRepositoryProvider).getHome();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeFeed = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('खबर', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeFeedProvider.future),
        child: homeFeed.when(
          data: (feed) => _HomeContent(feed: feed),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(homeFeedProvider)),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeFeed feed;

  const _HomeContent({required this.feed});

  void _openArticle(BuildContext context, String slug) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
  }

  @override
  Widget build(BuildContext context) {
    if (feed.hero == null && feed.latest.isEmpty) {
      return const EmptyStateView();
    }

    return ListView(
      children: [
        if (feed.hero != null) NewsHeroCard(article: feed.hero!, onTap: () => _openArticle(context, feed.hero!.slug)),
        if (feed.trending.isNotEmpty) const SectionHeader(title: 'ट्रेंडिंग न्यूज़'),
        if (feed.trending.isNotEmpty)
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: feed.trending.length,
              itemBuilder: (context, i) {
                final a = feed.trending[i];
                return TrendingCard(article: a, rank: i + 1, onTap: () => _openArticle(context, a.slug));
              },
            ),
          ),
        if (feed.categories.isNotEmpty) const SectionHeader(title: 'श्रेणी अनुसार खबरें'),
        if (feed.categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: feed.categories.length,
              itemBuilder: (context, i) {
                final c = feed.categories[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(c.name),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(slug: c.slug, name: c.name)),
                    ),
                  ),
                );
              },
            ),
          ),
        const SectionHeader(title: 'ताजा खबर'),
        ...feed.latest.map(
          (a) => NewsListTile(article: a, onTap: () => _openArticle(context, a.slug)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
