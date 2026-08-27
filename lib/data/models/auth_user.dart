/// Matches ApiController::authUser()'s safe shape — never carries
/// password_hash or any other internal `users` column.
class AuthUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String? avatar;
  final String? role;
  final String status;
  final String referralCode;
  final DateTime? createdAt;

  AuthUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    required this.status,
    required this.referralCode,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatar: json['avatar'] as String?,
        role: json['role'] as String?,
        status: json['status'] as String,
        referralCode: json['referral_code'] as String,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );
}
