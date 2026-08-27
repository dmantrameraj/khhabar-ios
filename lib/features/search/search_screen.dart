import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/news_article.dart';
import '../../widgets/news_card.dart';
import '../article/article_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<NewsArticle> _results = [];
  bool _loading = false;
  bool _searched = false;
  Object? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    // Wait for the user to pause typing before hitting the API — avoids
    // firing a request on every keystroke.
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });
    try {
      final result = await ref.read(newsRepositoryProvider).search(query);
      setState(() => _results = result.items);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search news...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searched) {
      return const Center(child: Text('Type to search articles.'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AsyncStateView(error: _error!, onRetry: () => _runSearch(_controller.text.trim()));
    }
    if (_results.isEmpty) {
      return const EmptyStateView(message: 'No results found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final article = _results[i];
        return NewsListTile(
          article: article,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ArticleScreen(slug: article.slug)),
          ),
        );
      },
    );
  }
}
