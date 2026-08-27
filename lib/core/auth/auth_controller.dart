import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_user.dart';
import '../providers.dart';
import '../push/push_service.dart';

/// Owns the app's session state: who's logged in (or null), the persisted
/// token, and the ApiClient's in-memory copy of it. Every screen reads
/// "am I logged in" through this rather than touching TokenStorage or
/// ApiClient's token directly.
///
/// login()/register() deliberately let ApiException propagate to the
/// caller instead of swallowing it into AsyncError — the calling screen
/// needs the exact message (e.g. "Incorrect email or password.") to show
/// inline, and state should stay untouched (still signed out) on failure
/// rather than flashing an error state across the whole app.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) {
      return null;
    }

    ref.read(apiClientProvider).setAuthToken(token);

    try {
      return await ref.read(authRepositoryProvider).me();
    } catch (_) {
      // Stored token is expired/invalid/revoked — sign out silently
      // rather than surfacing an error on app launch.
      await ref.read(tokenStorageProvider).clear();
      ref.read(apiClientProvider).setAuthToken(null);
      return null;
    }
  }

  Future<AuthUser> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
          deviceInfo: _deviceInfo(),
        );
    await _applySession(result.token, result.user);
    return result.user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          deviceInfo: _deviceInfo(),
        );
    await _applySession(result.token, result.user);
    return result.user;
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Ignore — we're clearing local session state regardless.
    }
    await ref.read(tokenStorageProvider).clear();
    ref.read(apiClientProvider).setAuthToken(null);
    PushService.onLogout();
    state = const AsyncData(null);
  }

  Future<void> _applySession(String token, AuthUser user) async {
    await ref.read(tokenStorageProvider).write(token);
    ref.read(apiClientProvider).setAuthToken(token);
    PushService.onLogin(user.uuid);
    state = AsyncData(user);
  }

  String _deviceInfo() {
    if (kIsWeb) {
      return 'Web browser';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android device';
      case TargetPlatform.iOS:
        return 'iOS device';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
