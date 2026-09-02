/// One of the signed-in reporter's own filed stories — matches
/// ApiController::reporterSubmissionItem(). Never shown to any reader
/// other than the reporter who filed it (see ReporterApiController).
class ReporterSubmission {
  final int id;
  final String title;
  final String slug;
  final String? featuredImage;
  final int categoryId;
  final String? categoryName;

  /// One of 'draft', 'pending', 'approved', 'published', 'rejected' — see
  /// storage/migrations/0022_two_stage_approval.sql for what each means.
  final String status;
  final String? rejectionReason;
  final int viewsCount;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  ReporterSubmission({
    required this.id,
    required this.title,
    required this.slug,
    required this.featuredImage,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.rejectionReason,
    required this.viewsCount,
    required this.createdAt,
    required this.publishedAt,
  });

  factory ReporterSubmission.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? const {};
    return ReporterSubmission(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      featuredImage: json['featured_image'] as String?,
      categoryId: category['id'] as int? ?? 0,
      categoryName: category['name'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
    );
  }
}
