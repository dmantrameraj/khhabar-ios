import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/auth_user.dart';

/// Token + the user it belongs to — what register/login both return.
class AuthResult {
  final String token;
  final AuthUser user;

  AuthResult({required this.token, required this.user});
}

/// Talks to /auth/* — matches docs/mobile-app/api-documentation.md's auth
/// endpoints. Screens never call ApiClient directly; AuthController is the
/// only caller of this repository (it owns session state + token storage).
class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceInfo,
  }) async {
    final (data, _) = await _client.post('auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (deviceInfo != null) 'device_info': deviceInfo,
    });
    return _toResult(data as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    String? deviceInfo,
  }) async {
    final (data, _) = await _client.post('auth/login', body: {
      'email': email,
      'password': password,
      if (deviceInfo != null) 'device_info': deviceInfo,
    });
    return _toResult(data as Map<String, dynamic>);
  }

  /// Best-effort — the caller (AuthController.logout()) clears local
  /// session state regardless of whether this succeeds, since the token
  /// may already be expired/invalid server-side.
  Future<void> logout() async {
    await _client.post('auth/logout');
  }

  Future<AuthUser> me() async {
    final (data, _) = await _client.get('auth/me');
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  /// [avatarPath] is a local file path (from image_picker) — optional,
  /// unlike the reporter submission's required photo.
  Future<AuthUser> updateProfile({
    required String name,
    String? phone,
    String? avatarPath,
  }) async {
    final file = avatarPath != null
        ? await MultipartFile.fromFile(avatarPath, filename: avatarPath.split(RegExp(r'[\\/]')).last)
        : null;
    final (data, _) = await _client.postMultipart(
      'auth/profile',
      fields: {'name': name, if (phone != null) 'phone': phone},
      file: file,
      fileField: 'avatar',
    );
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  AuthResult _toResult(Map<String, dynamic> data) => AuthResult(
        token: data['token'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
}
