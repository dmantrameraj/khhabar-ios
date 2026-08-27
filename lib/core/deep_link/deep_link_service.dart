import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/article/article_screen.dart';
import '../push/push_service.dart';
import '../utils/url_slug.dart';

/// Handles Android App Links / iOS Universal Links — a tap on
/// https://khhabar.com/news/{slug} (shared via WhatsApp, SMS, another app,
/// a browser bookmark, ...) opens that article directly in this app
/// instead of a browser, on any device where the OS has verified this
/// app's ownership of the domain:
///  - Android: /.well-known/assetlinks.json + the manifest's autoVerify
///    intent-filter (see AndroidManifest.xml).
///  - iOS: /.well-known/apple-app-site-association — NOT set up yet, since
///    there's no Apple Developer account / Team ID / bundle id to put in
///    it (iOS build itself is still blocked on Mac access). Add this once
///    that unblocks; the Dart-side handling below already covers iOS too.
///
/// Reuses PushService.navigatorKey (the same key wired into MaterialApp)
/// rather than a second global key — both features push onto the same
/// navigator, so there's only one to keep straight.
class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    // The link that cold-started the app, if any (e.g. tapped a link
    // while the app wasn't running).
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handle(initialUri);
      }
    } catch (_) {
      // No initial link, or the platform channel isn't ready yet — fine,
      // the app just opens normally.
    }

    // Links tapped while the app is already running (foreground/background).
    _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  static void _handle(Uri uri) {
    final slug = extractArticleSlug(uri.toString());
    if (slug != null) {
      PushService.navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
    }
  }
}
