/// AdMob ad unit IDs. `_useTestAds` ships `true` deliberately — Google's
/// test ad units always serve real-looking test creatives and NEVER count
/// as real impressions/clicks, so this is safe to leave on through every
/// debug build. Flip it to `false` and fill in the real ad unit IDs below
/// (from AdMob -> Apps -> Ad units) once the app has a real AdMob account,
/// and swap the matching AdMob App ID in android/app/src/main/AndroidManifest.xml
/// at the same time — a mismatched App ID/ad-unit pair fails to serve ads.
class AdConfig {
  AdConfig._();

  static const bool _useTestAds = true;

  // Google's public sample banner ad unit ID — https://developers.google.com/admob/android/test-ads
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  // TODO: replace with the real banner ad unit ID once available.
  static const String _productionBannerAdUnitId = 'ca-app-pub-REPLACE_ME/REPLACE_ME';

  static String get bannerAdUnitId => _useTestAds ? _testBannerAdUnitId : _productionBannerAdUnitId;
}
