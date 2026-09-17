import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ads/ad_config.dart';
import 'core/deep_link/deep_link_service.dart';
import 'core/push/push_service.dart';
import 'core/settings/user_preferences.dart';
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
  // BannerAdWidget carries the matching kIsWeb guard. Also gated on
  // AdConfig.adsEnabled (2026-09-17, ahead of Play Store submission) —
  // this used to run unconditionally, meaning the AdMob SDK contacted
  // Google and the advertising ID was collected on every launch even
  // though adsEnabled=false means no ad is ever actually requested or
  // shown. No behavior change for a real user (ads are still off), just
  // no longer collecting data for a feature nobody sees — one less
  // thing to declare on the Play Console Data Safety form. Re-enabling
  // ads later already means flipping AdConfig.adsEnabled to true; that
  // same flip now also turns this init back on, no separate step needed.
  if (!kIsWeb && AdConfig.adsEnabled) {
    await MobileAds.instance.initialize();
  }

  // Also awaited before runApp — theme mode (dark/light/system) has to be
  // known on the very first frame, or the app would flash light-then-dark
  // for anyone who picked dark mode.
  final prefs = await SharedPreferences.getInstance();

  // An explicit, shared ProviderContainer (rather than a plain
  // ProviderScope, which keeps its container private to the widget tree)
  // so PushService can read/write the same providers — auth state, the
  // ApiClient's token — that the rest of the app uses, not a second,
  // disconnected instance of them.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  runApp(UncontrolledProviderScope(container: container, child: const KhhabarApp()));

  // Fire-and-forget: fetches the OneSignal App ID from GET /config/push
  // and initializes push notifications. Safe to run after runApp — it
  // never blocks the UI, and no-ops cleanly if push isn't configured yet.
  PushService.initialize(container);

  // Fire-and-forget: picks up the link that cold-started the app (if any)
  // and starts listening for links tapped while it's already running.
  DeepLinkService.initialize();
}

class KhhabarApp extends ConsumerWidget {
  const KhhabarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: PushService.navigatorKey,
      title: 'Khhabar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const MainShell(),
    );
  }
}
