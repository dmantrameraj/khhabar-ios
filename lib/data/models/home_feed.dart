import 'news_article.dart';

/// Admin-curated hero image carousel (website's Admin -> Sliders).
/// [link] may point at an internal article (extractArticleSlug() picks
/// that out) or an arbitrary external URL — SliderSection decides which
/// at tap time.
class SliderItem {
  final int id;
  final String? title;
  final String imageUrl;
  final String? link;

  SliderItem({required this.id, this.title, required this.imageUrl, this.link});

  factory SliderItem.fromJson(Map<String, dynamic> json) => SliderItem(
        id: json['id'] as int,
        title: json['title'] as String?,
        imageUrl: json['image'] as String? ?? '',
        link: json['link'] as String?,
      );
}

class LiveUpdateItem {
  final int id;
  final String message;
  final String? postedBy;
  final String createdAt;

  LiveUpdateItem({required this.id, required this.message, this.postedBy, required this.createdAt});

  factory LiveUpdateItem.fromJson(Map<String, dynamic> json) => LiveUpdateItem(
        id: json['id'] as int,
        message: json['message'] as String? ?? '',
        postedBy: json['posted_by'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class CategoryTile {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final int articleCount;

  CategoryTile({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    required this.articleCount,
  });

  factory CategoryTile.fromJson(Map<String, dynamic> json) => CategoryTile(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        image: json['image'] as String?,
        articleCount: json['article_count'] as int? ?? 0,
      );
}

/// Everything GET /home returns in one call — see api-documentation.md.
class HomeFeed {
  final List<SliderItem> sliders;
  final NewsArticle? hero;
  final List<NewsArticle> latest;
  final List<NewsArticle> trending;
  final List<CategoryTile> categories;
  final List<LiveUpdateItem> liveUpdates;

  HomeFeed({
    required this.sliders,
    required this.hero,
    required this.latest,
    required this.trending,
    required this.categories,
    required this.liveUpdates,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
        sliders: (json['sliders'] as List? ?? const [])
            .map((e) => SliderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        hero: json['hero'] != null ? NewsArticle.fromJson(json['hero'] as Map<String, dynamic>) : null,
        latest: (json['latest'] as List).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList(),
        trending: (json['trending'] as List).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList(),
        categories:
            (json['categories'] as List).map((e) => CategoryTile.fromJson(e as Map<String, dynamic>)).toList(),
        liveUpdates:
            (json['live_updates'] as List).map((e) => LiveUpdateItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
