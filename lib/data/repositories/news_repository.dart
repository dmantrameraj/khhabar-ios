import '../../core/network/api_client.dart';
import '../models/article_detail.dart';
import '../models/breaking_item.dart';
import '../models/category_node.dart';
import '../models/comment.dart';
import '../models/home_feed.dart';
import '../models/news_article.dart';
import '../models/paginated_result.dart';

/// Everything the app knows about talking to the news API lives here —
/// screens never call ApiClient directly, so the JSON shape only has to
/// be understood in one place per feature. Matches
/// docs/mobile-app/api-documentation.md endpoint-for-endpoint.
class NewsRepository {
  final ApiClient _client;

  NewsRepository(this._client);

  /// [stateId] filters the 'latest' section to one state's articles (see
  /// ApiController::stateId() on the backend) — hero/trending/categories
  /// stay unfiltered, matching the reference behavior of location chips
  /// filtering the main feed list, not the whole home screen.
  Future<HomeFeed> getHome({String? lang, int? stateId}) async {
    final (data, _) = await _client.get('home', query: {
      if (lang != null) 'lang': lang,
      if (stateId != null) 'state_id': stateId,
    });
    return HomeFeed.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedResult<NewsArticle>> getNews({int page = 1, int? categoryId, String? lang, int? stateId}) async {
    final (data, meta) = await _client.get('news', query: {
      'page': page,
      if (categoryId != null) 'category_id': categoryId,
      if (lang != null) 'lang': lang,
      if (stateId != null) 'state_id': stateId,
    });
    return _paginatedArticles(data, meta);
  }

  /// Reused as the app's "Alerts" feed (the bell icon on Home) — same
  /// lightweight title+slug rows the website's breaking-news ticker uses.
  Future<List<BreakingItem>> getBreaking() async {
    final (data, _) = await _client.get('news/breaking');
    return (data as List).map((e) => BreakingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ArticleDetail> getArticle(String slug) async {
    final (data, _) = await _client.get('news/$slug');
    return ArticleDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CategoryNode>> getCategories() async {
    final (data, _) = await _client.get('categories');
    return (data as List).map((e) => CategoryNode.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns the category itself plus its paginated published articles —
  /// matches GET /categories/{slug}'s combined response shape.
  Future<(CategoryNode, PaginatedResult<NewsArticle>)> getCategoryArticles(
    String slug, {
    int page = 1,
  }) async {
    final (data, meta) = await _client.get('categories/$slug', query: {'page': page});
    final map = data as Map<String, dynamic>;
    final category = CategoryNode.fromJson(map['category'] as Map<String, dynamic>);
    final articles = (map['articles'] as List).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();

    return (category, _paginatedFromList(articles, meta));
  }

  Future<PaginatedResult<NewsArticle>> search(String query, {int page = 1}) async {
    final (data, meta) = await _client.get('search', query: {'q': query, 'page': page});
    return _paginatedArticles(data, meta);
  }

  /// Requires auth (the ApiClient must already have a token set — see
  /// AuthController). Returns (liked, likesCount) straight from the
  /// backend's response so the caller never has to guess the new count.
  Future<(bool, int)> toggleLike(String slug) async {
    final (data, _) = await _client.post('news/$slug/like');
    final map = data as Map<String, dynamic>;
    return (map['liked'] as bool, map['likes_count'] as int);
  }

  /// Requires auth. Returns the new bookmarked state.
  Future<bool> toggleBookmark(String slug) async {
    final (data, _) = await _client.post('news/$slug/bookmark');
    return (data as Map<String, dynamic>)['bookmarked'] as bool;
  }

  /// Requires auth. The caller's saved articles, most recently bookmarked first.
  Future<PaginatedResult<NewsArticle>> getBookmarks({int page = 1}) async {
    final (data, meta) = await _client.get('bookmarks', query: {'page': page});
    return _paginatedArticles(data, meta);
  }

  /// Public — top-level comments with their replies nested, oldest first.
  /// liked_by_me only resolves when the caller is authenticated.
  Future<List<Comment>> getComments(String slug) async {
    final (data, _) = await _client.get('news/$slug/comments');
    return (data as List).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Requires auth. Pass parentId to post a reply (server resolves a
  /// reply-to-a-reply up to the original top-level comment).
  Future<Comment> postComment(String slug, String content, {int? parentId}) async {
    final (data, _) = await _client.post('news/$slug/comments', body: {
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  /// Requires auth. Returns the new liked state.
  Future<bool> toggleCommentLike(int commentId) async {
    final (data, _) = await _client.post('comments/$commentId/like');
    return (data as Map<String, dynamic>)['liked'] as bool;
  }

  PaginatedResult<NewsArticle> _paginatedArticles(dynamic data, Map<String, dynamic> meta) {
    final items = (data as List).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
    return _paginatedFromList(items, meta);
  }

  PaginatedResult<T> _paginatedFromList<T>(List<T> items, Map<String, dynamic> meta) {
    return PaginatedResult<T>(
      items: items,
      page: meta['page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? items.length,
      total: meta['total'] as int? ?? items.length,
      hasNext: meta['has_next'] as bool? ?? false,
    );
  }
}
