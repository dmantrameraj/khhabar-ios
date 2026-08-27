import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token ("selector:validator") across app launches.
/// Backed by Android Keystore / iOS Keychain (and Web Crypto + localStorage
/// on web, used only for this project's own browser-based verification) —
/// deliberately never SharedPreferences, since that's plain-text storage
/// and this token is equivalent to a password for the account.
class TokenStorage {
  static const _key = 'khhabar_auth_token';

  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
