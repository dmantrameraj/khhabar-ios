import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp directly with the given text pre-filled, skipping the
/// generic OS share sheet — the dedicated-WhatsApp-button pattern readers
/// expect from Indian news apps (WhatsApp is the dominant share channel
/// here). Uses the universal `wa.me` link rather than the `whatsapp://`
/// scheme, because it works whether or not the WhatsApp app is installed
/// (falls back to WhatsApp Web / the Play Store listing).
///
/// This used to claim `wa.me` also avoided needing a `<queries>` entry in
/// AndroidManifest.xml — that was wrong, and it hid a real bug for a long
/// time. Android 11+ package-visibility filtering applies to VIEW+https
/// just as much as to a custom scheme, so with only the template's
/// PROCESS_TEXT query declared, this (and every other launchUrl call in
/// the app) silently did nothing on any modern device. The manifest now
/// declares https/http/mailto/tel explicitly; don't remove them.
Future<void> shareToWhatsApp(String text) async {
  final uri = Uri.https('wa.me', '/', {'text': text});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String articleShareText(String title, String slug) => '$title\n\nhttps://khhabar.com/news/$slug';
