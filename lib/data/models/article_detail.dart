import 'news_article.dart';

class MediaItem {
  final int id;
  final String type; // "image" | "video"
  final String url;
  final String? caption;
  final int? durationSeconds;

  MediaItem({required this.id, required this.type, required this.url, this.caption, this.durationSeconds});

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as int,
        type: json['type'] as String? ?? 'image',
        url: json['url'] as String? ?? '',
        caption: json['caption'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
      );
}

class RelatedArticle {
  final int id;
  final String title;
  final String slug;
  final String? featuredImage;
  final String publishedAt;
  final int viewsCount;

  RelatedArticle({
    required this.id,
    required this.title,
    required this.slug,
    this.featuredImage,
    required this.publishedAt,
    required this.viewsCount,
  });

  factory RelatedArticle.fromJson(Map<String, dynamic> json) => RelatedArticle(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        featuredImage: json['featured_image'] as String?,
        publishedAt: json['published_at'] as String? ?? '',
        viewsCount: json['views_count'] as int? ?? 0,
      );
}

class AdjacentLink {
  final String title;
  final String slug;

  AdjacentLink({required this.title, required this.slug});

  factory AdjacentLink.fromJson(Map<String, dynamic> json) => AdjacentLink(
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

/// GET /news/{slug} — a NewsArticle's fields (parsed via the same
/// NewsArticle.fromJson, which only reads the keys it needs and ignores
/// the extra detail fields) plus body content, tags, media, related
/// articles, and prev/next links.
class ArticleDetail {
  final NewsArticle article;
  final String content;
  final List<String> tags;
  final List<MediaItem> media;
  final List<RelatedArticle> related;
  final AdjacentLink? next;
  final AdjacentLink? prev;
  // False for a signed-out reader — the backend only resolves these when
  // the request carries a valid bearer token (see NewsApiController::show()).
  final bool liked;
  final bool bookmarked;

  ArticleDetail({
    required this.article,
    required this.content,
    required this.tags,
    required this.media,
    required this.related,
    this.next,
    this.prev,
    this.liked = false,
    this.bookmarked = false,
  });

  /// Returns a copy with liked/bookmarked/likesCount updated — used right
  /// after a successful toggle call so the UI updates instantly without
  /// refetching the whole article.
  ArticleDetail copyWith({bool? liked, bool? bookmarked, int? likesCount}) => ArticleDetail(
        article: likesCount != null ? article.copyWith(likesCount: likesCount) : article,
        content: content,
        tags: tags,
        media: media,
        related: related,
        next: next,
        prev: prev,
        liked: liked ?? this.liked,
        bookmarked: bookmarked ?? this.bookmarked,
      );

  factory ArticleDetail.fromJson(Map<String, dynamic> json) => ArticleDetail(
        article: NewsArticle.fromJson(json),
        content: json['content'] as String? ?? '',
        tags: (json['tags'] as List? ?? const []).map((e) => e as String).toList(),
        media: (json['media'] as List? ?? const [])
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        related: (json['related'] as List? ?? const [])
            .map((e) => RelatedArticle.fromJson(e as Map<String, dynamic>))
            .toList(),
        next: json['next'] != null ? AdjacentLink.fromJson(json['next'] as Map<String, dynamic>) : null,
        prev: json['prev'] != null ? AdjacentLink.fromJson(json['prev'] as Map<String, dynamic>) : null,
        liked: json['liked'] as bool? ?? false,
        bookmarked: json['bookmarked'] as bool? ?? false,
      );
}
