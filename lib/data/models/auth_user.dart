/// Matches ApiController::authUser()'s safe shape — never carries
/// password_hash or any other internal `users` column.
class AuthUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? role;
  final String status;
  final String referralCode;
  final DateTime? createdAt;

  /// Whether this account can actually submit news — the real
  /// `news.create` permission check (see ApiAuth::can() on the backend),
  /// not just role == 'reporter'. A super_admin has this too (full-access
  /// bypass), so the app can show/hide reporter tools correctly for any
  /// role without hardcoding role names.
  final bool canCreateNews;

  /// True for any of the admin-tier roles (super_admin or a location-tier
  /// *_admin) — purely a display label ("Admin" badge on the profile
  /// screen), not a permission check. Real admin actions all still happen
  /// on the website; nothing in the app branches on this beyond the badge.
  bool get isAdmin => role != null && role!.endsWith('admin');

  AuthUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.role,
    required this.status,
    required this.referralCode,
    required this.createdAt,
    required this.canCreateNews,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatar: json['avatar'] as String?,
        role: json['role'] as String?,
        status: json['status'] as String,
        referralCode: json['referral_code'] as String,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        canCreateNews: json['can_create_news'] as bool? ?? false,
      );
}
