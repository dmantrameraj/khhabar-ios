import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/home_feed.dart';
import '../../data/repositories/location_repository.dart';
import '../../widgets/news_card.dart';
import '../article/article_screen.dart';
import '../categories/category_detail_screen.dart';

final homeFeedProvider = FutureProvider<HomeFeed>((ref) {
  final stateId = ref.watch(selectedStateProvider)?.id;
  return ref.watch(newsRepositoryProvider).getHome(stateId: stateId);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeFeed = ref.watch(homeFeedProvider);
    final selectedState = ref.watch(selectedStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('खबर', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => _openLocationPicker(context, ref),
            icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
            label: Text(
              selectedState?.name ?? 'सभी राज्य',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeFeedProvider.future),
        child: homeFeed.when(
          data: (feed) => _HomeContent(feed: feed, filteredByState: selectedState?.name),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(homeFeedProvider)),
        ),
      ),
    );
  }

  Future<void> _openLocationPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<StateOption?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _StatePickerSheet(),
    );

    // A null RETURN VALUE from the sheet means "cancelled" (user tapped
    // outside or back) — distinct from selecting "All India", which the
    // sheet signals with its own explicit sentinel below.
    if (selected != _cancelled) {
      ref.read(selectedStateProvider.notifier).state = selected;
    }
  }
}

/// Distinguishes "picker dismissed without choosing" from "explicitly
/// chose All India" (both would otherwise pop null from the sheet).
const _cancelled = StateOption(id: -1, name: '__cancelled__');

class _StatePickerSheet extends ConsumerStatefulWidget {
  const _StatePickerSheet();

  @override
  ConsumerState<_StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends ConsumerState<_StatePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<StateOption>? _states;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final states = await ref.read(locationRepositoryProvider).getStates();
      if (mounted) {
        setState(() => _states = states);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    final filtered = states == null
        ? const <StateOption>[]
        : states.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('अपना राज्य चुनें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(_cancelled),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'राज्य खोजें...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _error != null
                ? Center(child: Text('राज्यों की सूची लोड नहीं हो सकी।\n$_error', textAlign: TextAlign.center))
                : states == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollController,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.public, color: AppTheme.accent),
                            title: const Text('सभी राज्य (All India)'),
                            onTap: () => Navigator.of(context).pop(null),
                          ),
                          const Divider(height: 1),
                          ...filtered.map(
                            (s) => ListTile(
                              title: Text(s.name),
                              onTap: () => Navigator.of(context).pop(s),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeFeed feed;
  final String? filteredByState;

  const _HomeContent({required this.feed, this.filteredByState});

  void _openArticle(BuildContext context, String slug) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
  }

  @override
  Widget build(BuildContext context) {
    if (feed.hero == null && feed.latest.isEmpty) {
      return EmptyStateView(
        message: filteredByState != null ? '$filteredByState में अभी कोई खबर नहीं है।' : 'No news found.',
      );
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
        SectionHeader(title: filteredByState != null ? '$filteredByState की ताजा खबर' : 'ताजा खबर'),
        ...feed.latest.map(
          (a) => NewsListTile(article: a, onTap: () => _openArticle(context, a.slug)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
