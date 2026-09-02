/// Simple on/off switches for features that are fully built and wired but
/// not meant to ship visible right now — same pattern as AdConfig.adsEnabled.
/// Flip a flag back to true to bring a feature back with no other code
/// changes needed.
class FeatureFlags {
  FeatureFlags._();

  /// The "लाइव अपडेट्स" card on Home (editor-posted short updates, pulled
  /// from the same GET /home response as everything else). Turned off per
  /// request — HomeScreen still fetches feed.liveUpdates either way, this
  /// only controls whether _LiveUpdatesCard renders.
  static const bool liveUpdatesEnabled = false;
}
