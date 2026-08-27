import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../data/repositories/config_repository.dart';
import '../../features/article/article_screen.dart';
import '../providers.dart';
import '../utils/url_slug.dart';

/// Wires the app into the same OneSignal account the website already uses
/// (Admin -> Push Notifications sends via PushNotifier.php's REST API call;
/// this is the client half that receives). The App ID is fetched from
/// GET /config/push rather than hardcoded, so turning push on/off from the
/// admin panel takes effect without an app update — see ConfigApiController.
///
/// Every article notification PushNotifier sends carries a `url` field
/// pointing at the article ("https://khhabar.com/news/{slug}") — on a
/// notification tap, this extracts the slug from wherever OneSignal
/// surfaces that URL and pushes ArticleScreen directly, whichever screen
/// the app happens to be on.
class PushService {
  PushService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool _initialized = false;

  /// Safe to call even when push is turned off server-side (GET /config/push
  /// returning enabled:false) or the app has no network yet — it just no-ops.
  static Future<void> initialize(ProviderContainer container) async {
    if (_initialized) {
      return;
    }

    PushConfig config;
    try {
      config = await container.read(configRepositoryProvider).getPushConfig();
    } catch (_) {
      // No network / backend not reachable yet — nothing to initialize.
      return;
    }

    if (!config.enabled || config.oneSignalAppId == null) {
      return;
    }

    _initialized = true;

    await OneSignal.initialize(config.oneSignalAppId!);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addClickListener((event) {
      final slug = _extractArticleSlug(event);
      if (slug != null) {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
      }
    });

    // Ties this device's OneSignal subscription to the app's own user id
    // when signed in — lets a future targeted send (e.g. "notify this one
    // reporter") reach the right device. Reflects whatever the auth state
    // is right now; AuthController.onLogin()/onLogout() keep it in sync
    // with every login/logout that happens after this.
    final authUser = container.read(authControllerProvider).value;
    if (authUser != null) {
      await OneSignal.login(authUser.uuid);
    }
  }

  /// Called by AuthController right after a successful login.
  static void onLogin(String userUuid) {
    if (_initialized) {
      OneSignal.login(userUuid);
    }
  }

  /// Called by AuthController right after logout.
  static void onLogout() {
    if (_initialized) {
      OneSignal.logout();
    }
  }

  static String? _extractArticleSlug(OSNotificationClickEvent event) {
    return extractArticleSlug(event.notification.launchUrl) ??
        extractArticleSlug(event.notification.additionalData?['url'] as String?);
  }
}
