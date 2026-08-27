import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Thrown on any API failure — success:false, a network error, or a
/// non-2xx status. `message` is always meant to be shown to the user
/// as-is (the backend already writes these to be human-readable, see
/// ApiResponse.php), so callers never need their own generic fallback
/// text for the common cases.
class ApiException implements Exception {
  final String message;
  final String? errorCode;

  ApiException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Thin wrapper around Dio that always unwraps Khhabar's API envelope
/// ({success, data, message, meta} — see api-documentation.md) before
/// returning to callers, so nothing above this layer needs to know the
/// envelope exists at all.
class ApiClient {
  final Dio _dio;

  /// The current session's bearer token ("selector:validator"), set by
  /// AuthController after login/register/restore and cleared on logout.
  /// Held here (not per-request) so every authenticated call — present
  /// and future (bookmarks, likes, comments) — picks it up automatically.
  String? _authToken;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Options get _authOptions => Options(
        headers: _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
      );

  /// Returns (data, meta) — `data` is the raw decoded JSON `data` field
  /// (a Map or a List depending on the endpoint); `meta` is always a Map
  /// (the backend guarantees this, even when empty — see ApiResponse.php).
  Future<(dynamic, Map<String, dynamic>)> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: query, options: _authOptions);
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<(dynamic, Map<String, dynamic>)> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post(path, data: body, options: _authOptions);
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  (dynamic, Map<String, dynamic>) _unwrap(Response response) {
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw ApiException(
        (body['message'] as String?) ?? 'Something went wrong.',
        errorCode: body['error_code'] as String?,
      );
    }

    return (
      body['data'],
      (body['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  // A 4xx/5xx error still carries our JSON envelope in e.response — reuse
  // its message instead of falling through to a generic one.
  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return ApiException(data['message'] as String, errorCode: data['error_code'] as String?);
    }
    return ApiException('Could not connect. Please check your internet connection.');
  }
}
