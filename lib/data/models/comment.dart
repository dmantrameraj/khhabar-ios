/// Matches ApiController::commentItem()'s safe shape — never carries
/// ip_address, status, guest_email, or user_id.
class Comment {
  final int id;
  final String content;
  final String createdAt;
  final String authorName;
  final String? authorAvatar;
  final int likeCount;
  final bool likedByMe;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.authorAvatar,
    required this.likeCount,
    required this.likedByMe,
    required this.replies,
  });

  /// Used after a successful like toggle or a new reply being posted, so
  /// the UI updates instantly without refetching the whole thread.
  Comment copyWith({int? likeCount, bool? likedByMe, List<Comment>? replies}) => Comment(
        id: id,
        content: content,
        createdAt: createdAt,
        authorName: authorName,
        authorAvatar: authorAvatar,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        replies: replies ?? this.replies,
      );

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? const {};
    return Comment(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      authorName: author['name'] as String? ?? 'Reader',
      authorAvatar: author['avatar'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      replies:
          (json['replies'] as List? ?? const []).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
