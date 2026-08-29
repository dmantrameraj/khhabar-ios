import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp directly with the given text pre-filled, skipping the
/// generic OS share sheet — the dedicated-WhatsApp-button pattern readers
/// expect from Indian news apps (WhatsApp is the dominant share channel
/// here). Uses the universal `wa.me` link rather than the `whatsapp://`
/// scheme: it works whether or not the WhatsApp app is installed (falls
/// back to WhatsApp Web / the Play Store listing), and needs no extra
/// `<queries>` entry in AndroidManifest.xml the way `whatsapp://` would.
Future<void> shareToWhatsApp(String text) async {
  final uri = Uri.https('wa.me', '/', {'text': text});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String articleShareText(String title, String slug) => '$title\n\nhttps://khhabar.com/news/$slug';
