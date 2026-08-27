import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/news_article.dart';
import '../../widgets/news_card.dart';
import '../article/article_screen.dart';

/// Articles within one category (or its subcategories), with infinite
/// scroll — matches the website's own category page pagination.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final String name;

  const CategoryDetailScreen({super.key, required this.slug, required this.name});

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final List<NewsArticle> _articles = [];
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _hasNext = true;
  bool _loading = false;
  bool _initialLoading = true;
  Object? _error;

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
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
