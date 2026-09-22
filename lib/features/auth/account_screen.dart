import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';
import '../../widgets/location_picker.dart';
import '../alerts/alerts_screen.dart';
import '../reporter/reporter_earnings_screen.dart';
import '../reporter/reporter_submissions_screen.dart';
import '../reporter/reporter_submit_screen.dart';
import '../settings/favorite_categories_screen.dart';
import '../settings/font_size_sheet.dart';
import '../settings/theme_mode_sheet.dart';
import 'bookmarks_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

/// The Play Store package id (see android/app/build.gradle.kts's
/// applicationId) — used for the "ऐप को रेटिंग दें" link. Resolves fine
/// even before the app is published (Play Store just shows "not found"
/// until then; the link itself needs no change once it goes live).
///
/// Changed 2026-09-22: the original applicationId (com.khhabar.khhabar_app,
/// the Flutter template default) didn't match com.khhabar.app, the package
/// name already locked into the just-created Play Console listing — Play
/// rejected every .aab upload over the mismatch. Package names lock
/// permanently the moment an app is first registered in Play Console, so
/// the app's applicationId had to change to match, not the other way
/// around. Kept in sync with android/app/build.gradle.kts's applicationId
/// and public/.well-known/assetlinks.json's package_name on the backend
/// (App Links verification breaks if that file still names the old id).
const _playStorePackageId = 'com.khhabar.app';

/// The bottom-nav "Account" tab — signed-out prompt or signed-in profile,
/// driven entirely by authControllerProvider so it always reflects the
/// current session (including a silent sign-out if a stored token turns
/// out to be expired/revoked on restore).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रोफाइल'),
        // Compact login entry point, top-right — replaces the old
        // full-width "Log In" button buried in the signed-out body, per
        // request/reference design. Only shown while signed out; the
        // signed-in view has its own profile card instead.
        actions: [
          if (user == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('लॉगिन'),
                ),
              ),
            ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your account. Please restart the app.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (user) => user == null ? const _SignedOutView() : _SignedInView(user: user),
      ),
    );
  }
}

/// Shown to every reader before they log in — not a login wall, a real,
/// useful settings menu (matches what most news apps offer any fresh
/// install) with login moved to the app bar instead of blocking this
/// whole screen. The already-approved signed-in profile (`_SignedInView`
/// below) is untouched by this — these are two entirely separate views.
class _SignedOutView extends ConsumerWidget {
  const _SignedOutView();

  void _requireLogin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuGroup(items: [
          _MenuItem(
            icon: Icons.notifications_outlined,
            iconColor: AppTheme.accent,
            title: 'नोटिफिकेशन',
            subtitle: 'ताज़ा अलर्ट देखें',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),
          _MenuItem(
            icon: Icons.dark_mode_outlined,
            iconColor: AppTheme.navy,
            title: 'डार्क मोड',
            subtitle: 'लाइट, डार्क या सिस्टम के अनुसार',
            onTap: () => openThemeModeSheet(context),
          ),
          _MenuItem(
            icon: Icons.format_size,
            iconColor: Colors.deepPurple,
            title: 'आर्टिकल फ़ॉन्ट साइज़',
            subtitle: 'पढ़ने का साइज़ छोटा, मध्यम या बड़ा करें',
            onTap: () => openFontSizeSheet(context),
          ),
          _MenuItem(
            icon: Icons.category_outlined,
            iconColor: Colors.teal,
            title: 'मेरा पसंदीदा विषय',
            subtitle: 'पसंदीदा विषय होम पर सबसे पहले दिखेंगे',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoriteCategoriesScreen())),
          ),
        ]),
        const SizedBox(height: 12),
        _MenuGroup(items: [
          _MenuItem(
            icon: Icons.person_add_alt_outlined,
            iconColor: Colors.green,
            title: 'दोस्तों को इन्वाइट करें',
            subtitle: 'Khhabar ऐप अपने दोस्तों के साथ शेयर करें',
            onTap: () => Share.share('Khhabar पर ताज़ा खबरें पढ़ें: https://khhabar.com'),
          ),
          _MenuItem(
            icon: Icons.star_outline,
            iconColor: Colors.amber.shade800,
            title: 'ऐप को रेटिंग दें',
            subtitle: 'Play Store पर हमें रेट करें',
            onTap: () => launchUrl(
              Uri.parse('https://play.google.com/store/apps/details?id=$_playStorePackageId'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _MenuGroup(items: [
          _MenuItem(
            icon: Icons.location_on_outlined,
            iconColor: AppTheme.accent,
            title: 'अपना राज्य चुनें',
            subtitle: 'अपने राज्य की खबरें देखें',
            onTap: () => openLocationPicker(context, ref),
          ),
          _MenuItem(
            icon: Icons.bookmark_outline,
            iconColor: AppTheme.navy,
            title: 'सेव आर्टिकल्स',
            subtitle: 'सेव करने के लिए लॉगिन करें',
            onTap: () => _requireLogin(context),
          ),
        ]),
      ],
    );
  }
}

class _SignedInView extends ConsumerWidget {
  final AuthUser user;

  const _SignedInView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(user: user),
        const SizedBox(height: 16),
        // Reporter/admin-only: matches the `news.create` permission the
        // backend actually enforces (see ReporterApiController) — reads
        // AuthUser.canCreateNews (a real permission check from /auth/me),
        // not a hardcoded role name, so it's correct for any role the
        // backend ever grants news.create to (reporter today, potentially
        // others later).
        if (user.canCreateNews) ...[
          _MenuGroup(items: [
            _MenuItem(
              icon: Icons.send_outlined,
              iconColor: AppTheme.accent,
              title: 'खबर भेजें',
              subtitle: 'अपनी खबर, फ़ोटो भेजें',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReporterSubmitScreen())),
            ),
            _MenuItem(
              icon: Icons.description_outlined,
              iconColor: Colors.orange,
              title: 'मेरी भेजी गई खबरें',
              subtitle: 'भेजी गई खबरों की स्थिति देखें',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReporterSubmissionsScreen())),
            ),
            _MenuItem(
              icon: Icons.currency_rupee,
              iconColor: Colors.green,
              title: 'मेरी कमाई',
              subtitle: 'बकाया और भुगतान की गई राशि',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReporterEarningsScreen())),
            ),
          ]),
          const SizedBox(height: 12),
        ],
        _MenuGroup(items: [
          _MenuItem(
            icon: Icons.bookmark_outline,
            iconColor: AppTheme.navy,
            title: 'सेव की गई खबरें',
            subtitle: 'आपकी सेव की गई खबरें',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey.shade700,
            title: 'प्राइवेसी और सुरक्षा',
            subtitle: 'प्राइवेसी नीति देखें',
            onTap: () => launchUrl(Uri.parse('https://khhabar.com/page/privacy-policy'), mode: LaunchMode.externalApplication),
          ),
        ]),
        const SizedBox(height: 12),
        _MenuGroup(items: [
          _MenuItem(
            icon: Icons.logout,
            iconColor: Colors.red.shade700,
            title: 'लॉगआउट',
            subtitle: 'अपने अकाउंट से लॉगआउट करें',
            onTap: () => _confirmLogout(context, ref),
          ),
        ]),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Log Out')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// Avatar + name + contact + a "KHHABAR ID" badge (the account's referral
/// code, reused for this — there's no separate short-ID field) + an Edit
/// Profile button — matches the reference design's top card.
class _ProfileCard extends StatelessWidget {
  final AuthUser user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.isAdmin ? 'एडमिन' : (user.canCreateNews ? 'रिपोर्टर' : null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.navy,
                  backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
                  child: user.avatar == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (roleLabel != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone ?? user.email,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 5),
                    Text(
                      'KHHABAR ID: ${user.referralCode}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.accent),
                label: const Text('प्रोफाइल एडिट करें', style: TextStyle(color: AppTheme.accent)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
