class Category {
  final int id;
  final String name;
  final String slug;

  Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

class Author {
  final int id;
  final String name;

  Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );
}

/// Matches the API's "news card" shape exactly (see
/// docs/mobile-app/api-documentation.md) — every list endpoint (home,
/// news, category, search, trending) returns this same shape.
class NewsArticle {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final String? subHeading;
  final String? excerpt;
  final String? featuredImage;
  final Category category;
  final Author author;
  final String? state;
  final String language;
  final bool isBreaking;
  final bool isFeatured;
  final bool isTrending;
  final int viewsCount;
  final int likesCount;
  final int readingTimeMinutes;
  final String publishedAt;

  NewsArticle({
    required this.id,
    required this.uuid,
    required this.title,
    required this.slug,
    this.subHeading,
    this.excerpt,
    this.featuredImage,
    required this.category,
    required this.author,
    this.state,
    required this.language,
    required this.isBreaking,
    required this.isFeatured,
    required this.isTrending,
    required this.viewsCount,
    required this.likesCount,
    required this.readingTimeMinutes,
    required this.publishedAt,
  });

  /// Used after a successful like toggle to reflect the server's returned
  /// count instantly, without refetching the whole article.
  NewsArticle copyWith({int? likesCount}) => NewsArticle(
        id: id,
        uuid: uuid,
        title: title,
        slug: slug,
        subHeading: subHeading,
        excerpt: excerpt,
        featuredImage: featuredImage,
        category: category,
        author: author,
        state: state,
        language: language,
        isBreaking: isBreaking,
        isFeatured: isFeatured,
        isTrending: isTrending,
        viewsCount: viewsCount,
        likesCount: likesCount ?? this.likesCount,
        readingTimeMinutes: readingTimeMinutes,
        publishedAt: publishedAt,
      );

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        id: json['id'] as int,
        uuid: json['uuid'] as String? ?? '',
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        subHeading: json['sub_heading'] as String?,
        excerpt: json['excerpt'] as String?,
        featuredImage: json['featured_image'] as String?,
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        author: Author.fromJson(json['author'] as Map<String, dynamic>),
        state: json['state'] as String?,
        language: json['language'] as String? ?? 'hi',
        isBreaking: json['is_breaking'] as bool? ?? false,
        isFeatured: json['is_featured'] as bool? ?? false,
        isTrending: json['is_trending'] as bool? ?? false,
        viewsCount: json['views_count'] as int? ?? 0,
        likesCount: json['likes_count'] as int? ?? 0,
        readingTimeMinutes: json['reading_time_minutes'] as int? ?? 1,
        publishedAt: json['published_at'] as String? ?? '',
      );
}
