import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/deep_link/deep_link_service.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Awaited, not fire-and-forget: BannerAdWidget lives in the very first
  // frame (inside MainShell), so if it started requesting an ad before
  // the native AdMob SDK finished initializing, that race could throw
  // before anything ever painted — this makes sure the SDK is ready
  // first. google_mobile_ads only ships Android/iOS platform
  // implementations (no web) — guarded so this app still runs under
  // `flutter run -d web-server`, which is how this project verifies
  // changes locally (no Android emulator in this environment).
  // BannerAdWidget carries the matching kIsWeb guard.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // An explicit, shared ProviderContainer (rather than a plain
  // ProviderScope, which keeps its container private to the widget tree)
  // so PushService can read/write the same providers — auth state, the
  // ApiClient's token — that the rest of the app uses, not a second,
  // disconnected instance of them.
  final container = ProviderContainer();

  runApp(UncontrolledProviderScope(container: container, child: const KhhabarApp()));

  // Fire-and-forget: fetches the OneSignal App ID from GET /config/push
  // and initializes push notifications. Safe to run after runApp — it
  // never blocks the UI, and no-ops cleanly if push isn't configured yet.
  PushService.initialize(container);

  // Fire-and-forget: picks up the link that cold-started the app (if any)
  // and starts listening for links tapped while it's already running.
  DeepLinkService.initialize();
}

class KhhabarApp extends StatelessWidget {
  const KhhabarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushService.navigatorKey,
      title: 'Khhabar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
