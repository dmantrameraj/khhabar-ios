import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/models/news_article.dart';
import '../features/article/article_screen.dart';
import 'news_card.dart';

/// One category's paginated, infinite-scroll article list — no Scaffold
/// or AppBar of its own, so it can be embedded either as a whole screen's
/// body (CategoryDetailScreen) or as one page of Home's swipeable
/// category tabs (HomeScreen). Extracted so both places share the exact
/// same pagination/error/empty behavior instead of drifting apart.
class CategoryFeedList extends ConsumerStatefulWidget {
  final String slug;

  const CategoryFeedList({super.key, required this.slug});

  @override
  ConsumerState<CategoryFeedList> createState() => _CategoryFeedListState();
}

class _CategoryFeedListState extends ConsumerState<CategoryFeedList>
    with AutomaticKeepAliveClientMixin {
  final List<NewsArticle> _articles = [];
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _hasNext = true;
  bool _loading = false;
  bool _initialLoading = true;
  Object? _error;

  // Keeps a tab's scroll position/loaded articles when the user swipes
  // away to a sibling tab and back, instead of refetching from scratch.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _loading) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(newsRepositoryProvider);
      final (_, result) = await repo.getCategoryArticles(widget.slug, page: _page);
      setState(() {
        _articles.addAll(result.items);
        _hasNext = result.hasNext;
        _page++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _articles.clear();
      _page = 1;
      _hasNext = true;
      _initialLoading = true;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _articles.isEmpty) {
      return AsyncStateView(error: _error!, onRetry: _loadPage);
    }
    if (_articles.isEmpty) {
      return const EmptyStateView(message: 'No articles in this category yet.');
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _articles.length + (_hasNext ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _articles.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final article = _articles[i];
          return NewsListTile(
            article: article,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArticleScreen(slug: article.slug)),
            ),
          );
        },
      ),
    );
  }
}
