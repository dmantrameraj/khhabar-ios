import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/providers.dart';
import '../../core/settings/user_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_node.dart';
import '../../data/models/home_feed.dart';
import '../../data/models/news_article.dart';
import '../../widgets/category_feed_list.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/news_card.dart';
import '../../widgets/slider_section.dart';
import '../alerts/alerts_screen.dart';
import '../article/article_screen.dart';

final homeFeedProvider = FutureProvider<HomeFeed>((ref) {
  final stateId = ref.watch(selectedStateProvider)?.id;
  return ref.watch(newsRepositoryProvider).getHome(stateId: stateId);
});

/// Top-level categories shown as swipeable tabs across the top of Home
/// (होम + each category — swiping the body changes which one is showing,
/// matching the reference apps). Same list feeds the reporter's category
/// picker on the submit-article screen.
///
/// These tabs are foundational navigation, not just one more widget on the
/// page — if the very first GET /categories call hits a transient network
/// blip (a phone flipping between wifi/cellular right as the app opens is a
/// common real case) and nothing retries it, the app is left showing only
/// "Home" for the rest of the session with no visible error and no way to
/// recover short of a restart. Retry a couple of times before giving up;
/// `_refresh()` (Home's pull-to-refresh) also invalidates this provider as
/// a manual fallback.
final topCategoriesProvider = FutureProvider<List<CategoryNode>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  for (var attempt = 0; ; attempt++) {
    try {
      return await repo.getCategories();
    } catch (_) {
      if (attempt >= 2) rethrow;
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedState = ref.watch(selectedStateProvider);
    // Home's own tab renders as soon as this screen builds; the category
    // tabs beside it pop in once GET /categories resolves (DefaultTabController
    // recreates itself when `length` changes) rather than blocking the
    // whole screen behind a spinner for a row that's secondary to the feed.
    final rawCategories = ref.watch(topCategoriesProvider).valueOrNull ?? const <CategoryNode>[];
    // Categories the reader marked as favorite (Account -> "मेरा पसंदीदा
    // विषय") sort first, right after Home — real personalization, not
    // just a saved-but-inert preference. Relative order within each group
    // (favorited / not) is left as the backend returns it.
    final favoriteSlugs = ref.watch(favoriteCategoriesProvider);
    final categories = favoriteSlugs.isEmpty
        ? rawCategories
        : [
            ...rawCategories.where((c) => favoriteSlugs.contains(c.slug)),
            ...rawCategories.where((c) => !favoriteSlugs.contains(c.slug)),
          ];

    return DefaultTabController(
      length: 1 + categories.length,
      child: Scaffold(
        appBar: AppBar(
          // The real wordmark image, per request — replaces the earlier
          // styled-text version. The source PNG has an opaque white
          // background baked in (not transparent), so it's wrapped in a
          // matching white badge rather than placed directly on the navy
          // bar, which would otherwise show as an ugly white rectangle.
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/splash/khhabar_splash_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          // Left-aligned per request — sits above the "Home" tab's left
          // edge rather than centered across the whole bar.
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'अलर्ट',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
            ),
            TextButton.icon(
              onPressed: () => openLocationPicker(context, ref),
              // AppBar only ever gives this actions row ~143px total
              // (confirmed live: a RenderFlex overflow by ~9px at a
              // 375px-wide screen with the button's default padding) —
              // shrink the tap target/padding to Material's minimum
              // rather than its default touch-friendly size, and cap the
              // label's width so a long state name still ellipsizes
              // instead of the row overflowing again.
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 48),
                child: Text(
                  selectedState?.name ?? 'सभी राज्य',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Home'),
              ...categories.map((c) => Tab(text: c.name)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _HomeFeedTab(),
            ...categories.map((c) => CategoryFeedList(slug: c.slug)),
          ],
        ),
      ),
    );
  }
}

/// The "Home" tab's content: a fixed header (sliders/hero/live-updates/
/// trending, from the single GET /home call) followed by "ताजा खबर" —
/// genuinely paginated via GET /news, loading continuously as the reader
/// scrolls, all inside ONE CustomScrollView so "near the bottom" is
/// detected across the whole tab, not just the paginated section.
///
/// Deliberately does NOT reuse /home's own `latest` array as page one of
/// this pagination: /home and /news aren't guaranteed to share the exact
/// same page size, so treating one as a continuation of the other risked
/// duplicate or skipped articles at the seam. Instead this section is
/// entirely self-contained, calling GET /news from page 1 on its own —
/// same principle as CategoryFeedList, just embedded in a shared sliver
/// scroll view instead of owning its own ListView.
class _HomeFeedTab extends ConsumerStatefulWidget {
  const _HomeFeedTab();

  @override
  ConsumerState<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends ConsumerState<_HomeFeedTab> {
  final ScrollController _scrollController = ScrollController();
  final List<NewsArticle> _latest = [];
  int _page = 1;
  bool _hasNext = true;
  bool _loadingMore = false;
  bool _initialLoading = true;
  Object? _latestError;
  int? _stateId;

  @override
  void initState() {
    super.initState();
    _stateId = ref.read(selectedStateProvider)?.id;
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _loadingMore || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await ref.read(newsRepositoryProvider).getNews(page: _page, stateId: _stateId);
      setState(() {
        _latest.addAll(result.items);
        _hasNext = result.hasNext;
        _page++;
        _latestError = null;
      });
    } catch (e) {
      setState(() => _latestError = e);
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
          _initialLoading = false;
        });
      }
    }
  }

  void _resetAndReload() {
    setState(() {
      _latest.clear();
      _page = 1;
      _hasNext = true;
      _initialLoading = true;
      _latestError = null;
    });
    _loadMore();
  }

  Future<void> _refresh() async {
    ref.invalidate(homeFeedProvider);
    // Also retries the category tabs — see topCategoriesProvider's doc for
    // why they're worth an explicit recovery path here.
    ref.invalidate(topCategoriesProvider);
    _resetAndReload();
  }

  void _openArticle(String slug) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
  }

  @override
  Widget build(BuildContext context) {
    // The location filter lives outside this widget (Home's AppBar) —
    // when it changes, this pagination has to restart from page 1 rather
    // than silently keep appending pages fetched under the old filter.
    ref.listen(selectedStateProvider, (previous, next) {
      final newStateId = next?.id;
      if (newStateId != _stateId) {
        _stateId = newStateId;
        _resetAndReload();
      }
    });

    final homeFeed = ref.watch(homeFeedProvider);
    final filteredByState = ref.watch(selectedStateProvider)?.name;
    final heroSlug = homeFeed.valueOrNull?.hero?.slug;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: homeFeed.when(
              data: (feed) => _HomeHeader(feed: feed, onOpenArticle: _openArticle),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SizedBox(
                height: 220,
                child: AsyncStateView(error: err, onRetry: () => ref.invalidate(homeFeedProvider)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(title: filteredByState != null ? '$filteredByState की ताजा खबर' : 'ताजा खबर'),
          ),
          if (_initialLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_latestError != null && _latest.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(height: 260, child: AsyncStateView(error: _latestError!, onRetry: _loadMore)),
            )
          else if (_latest.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: EmptyStateView(
                  message: filteredByState != null ? '$filteredByState में अभी कोई खबर नहीं है।' : 'No news found.',
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _latest.length + (_hasNext ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _latest.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final a = _latest[i];
                // The newest article is very often both /home's hero AND
                // page 1's first "latest" result (they're independently
                // fetched — see the class doc — so there's no shared
                // pagination cursor to simply skip it at the source).
                // Hiding the duplicate here avoids showing the same
                // headline twice in a row right under the hero card.
                if (a.slug == heroSlug) {
                  return const SizedBox.shrink();
                }
                return NewsFeedCard(article: a, onTap: () => _openArticle(a.slug));
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// The fixed, non-paginated part of Home — sliders/hero/live-updates/
/// trending, straight from the single GET /home call.
class _HomeHeader extends StatelessWidget {
  final HomeFeed feed;
  final void Function(String slug) onOpenArticle;

  const _HomeHeader({required this.feed, required this.onOpenArticle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (feed.sliders.isNotEmpty) SliderSection(sliders: feed.sliders),
        if (feed.hero != null) NewsHeroCard(article: feed.hero!, onTap: () => onOpenArticle(feed.hero!.slug)),
        if (FeatureFlags.liveUpdatesEnabled && feed.liveUpdates.isNotEmpty) _LiveUpdatesCard(updates: feed.liveUpdates),
        if (FeatureFlags.trendingNewsEnabled && feed.trending.isNotEmpty) const SectionHeader(title: 'ट्रेंडिंग न्यूज़'),
        if (FeatureFlags.trendingNewsEnabled && feed.trending.isNotEmpty)
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: feed.trending.length,
              itemBuilder: (context, i) {
                final a = feed.trending[i];
                return TrendingCard(article: a, rank: i + 1, onTap: () => onOpenArticle(a.slug));
              },
            ),
          ),
      ],
    );
  }
}

/// Editor-posted live updates (short, timestamped notes — election
/// results ticking in, a developing story, etc.) — fetched by GET /home
/// already, gated behind FeatureFlags.liveUpdatesEnabled.
class _LiveUpdatesCard extends StatelessWidget {
  final List<LiveUpdateItem> updates;

  const _LiveUpdatesCard({required this.updates});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: AppTheme.navy,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'लाइव अपडेट्स',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...updates.take(5).map(
                  (u) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        if (u.postedBy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              u.postedBy!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
