import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// "संपर्क करें" — the app's contact page.
///
/// This exists because Google Play **rejected** the app on 2026-09-24
/// under the News and Magazines policy: "Doesn't contain a dedicated
/// website and in-app page that's easy to find and clearly shows relevant
/// contact information." The app genuinely had no contact screen at all,
/// and the website's own Contact page was still unedited placeholder text
/// ("[INSERT EMAIL]"), so a reviewer had nowhere to find a real address.
///
/// Policy requirements this screen is built to satisfy — keep them in mind
/// before changing anything here:
///   - a real email address OR phone number, belonging to the app or its
///     developer (social media links explicitly do NOT count)
///   - clearly labelled as contact information
///   - easy to find (this is reachable in two taps: Account tab → संपर्क करें,
///     and is deliberately in the FIRST menu group, not buried in settings)
///
/// Everything here is hardcoded on purpose. A reviewer may open this screen
/// with no network, on a fresh install, before signing in — fetching it from
/// the API would risk showing an empty page in exactly the situation the
/// policy is about. These values must stay identical to the website's
/// /page/contact-us and to Play Console's "Store listing contact details";
/// Google cross-checks all three.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _email = 'prabhatsingh2223@gmail.com';
  static const String _phoneDisplay = '+91 70078 02901';
  static const String _phoneDial = '+917007802901';
  static const String _address = 'Raja Market, Jhanjhari, Block Gonda,\nUttar Pradesh - 271001, भारत';
  static const String _website = 'https://khhabar.com';
  static const String _editorialEmail = 'khhabarnews@gmail.com';

  Future<void> _launch(Uri uri) async {
    // Deliberately swallows failures rather than surfacing an error: if a
    // device has no mail/dialer app the tap simply does nothing, but the
    // address is still displayed as plain selectable text above — the
    // contact information stays readable either way, which is what the
    // policy actually requires.
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignored — see above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('संपर्क करें')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khhabar (खबर)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'हिंदी समाचार पोर्टल — khhabar.com का आधिकारिक ऐप',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'किसी भी खबर, सुझाव, सुधार या शिकायत के लिए हमसे संपर्क करें:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _ContactTile(
            icon: Icons.email_outlined,
            iconColor: AppTheme.accent,
            label: 'ईमेल',
            value: _email,
            onTap: () => _launch(Uri.parse('mailto:$_email')),
          ),
          _ContactTile(
            icon: Icons.phone_outlined,
            iconColor: Colors.green.shade700,
            label: 'फ़ोन',
            value: _phoneDisplay,
            onTap: () => _launch(Uri.parse('tel:$_phoneDial')),
          ),
          _ContactTile(
            icon: Icons.location_on_outlined,
            iconColor: AppTheme.navy,
            label: 'पता',
            value: _address,
          ),
          _ContactTile(
            icon: Icons.language,
            iconColor: Colors.blue.shade700,
            label: 'वेबसाइट',
            value: 'khhabar.com',
            onTap: () => _launch(Uri.parse(_website)),
          ),
          const SizedBox(height: 20),
          const Text(
            'संपादकीय / खबर से जुड़े विषय',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.newspaper_outlined,
            iconColor: Colors.deepPurple,
            label: 'समाचार डेस्क',
            value: _editorialEmail,
            onTap: () => _launch(Uri.parse('mailto:$_editorialEmail')),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'खबर में किसी त्रुटि की सूचना देने के लिए कृपया खबर का लिंक और '
              'त्रुटि का विवरण भेजें। पुष्टि होने पर हम उसे सुधारते हैं।',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        // SelectableText so the address stays copyable even where no app
        // handles the tap (a reviewer must always be able to read/copy it).
        subtitle: SelectableText(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
