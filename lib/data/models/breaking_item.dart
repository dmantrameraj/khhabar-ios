/// GET /news/breaking's row shape — deliberately just title+slug (a
/// lightweight ticker query on the backend, not a full article row). See
/// NewsApiController::breaking().
class BreakingItem {
  final String title;
  final String slug;

  BreakingItem({required this.title, required this.slug});

  factory BreakingItem.fromJson(Map<String, dynamic> json) => BreakingItem(
        title: json['title'] as String,
        slug: json['slug'] as String,
      );
}
