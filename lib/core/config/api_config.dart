/// Central place for the API base URL — nothing else in the app should
/// hardcode it. See E:\khhabar\docs\mobile-app\api-documentation.md for
/// the full endpoint contract this app talks to.
class ApiConfig {
  ApiConfig._();

  /// The live Khhabar website's REST API — the same PHP/MySQL backend
  /// that powers khhabar.com, never a separate database.
  static const String baseUrl = 'https://khhabar.com/apis/v1/';
}
