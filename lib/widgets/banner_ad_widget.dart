import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_config.dart';

/// A width-adaptive AdMob banner — sized to the device's actual screen
/// width rather than a fixed 320x50, per Google's current recommendation.
/// Renders nothing (zero height, not even a placeholder box) until the ad
/// has actually loaded, and again if it fails to load — a persistently
/// broken/empty ad slot is worse for the reader than no ad at all.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _requestedForThisWidth = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ads are built and wired but turned off for now (AdConfig.adsEnabled)
    // — held back for a later add-on pass rather than removed outright.
    if (!AdConfig.adsEnabled) {
      return;
    }
    // google_mobile_ads has no web implementation — this app still needs
    // to run under `flutter run -d web-server` for local verification
    // (no Android emulator in this environment), so this stays a
    // permanent no-op on web rather than a temporary dev-only skip.
    if (kIsWeb) {
      return;
    }
    // getAnchoredAdaptiveBannerAdSize needs the current screen width, which
    // is only reliably available once dependencies (MediaQuery) resolve —
    // guarded so a single ad is requested per widget instance, not on
    // every rebuild.
    if (!_requestedForThisWidth) {
      _requestedForThisWidth = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // Never let anything in here reach an uncaught exception — an ad
    // slot is expendable; the rest of the app is not. Defensive on
    // purpose: this whole widget sits in the very first frame (inside
    // MainShell), so a crash here would take the whole app down with it.
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(Orientation.portrait, width);
      if (size == null || !mounted) {
        return;
      }

      final ad = BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() => _bannerAd = ad as BannerAd);
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      );
      ad.load();
    } catch (_) {
      // Ad SDK not ready / not available on this device — no ad shown, app continues normally.
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
