import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';
import '../reporter/reporter_earnings_screen.dart';
import '../reporter/reporter_submissions_screen.dart';
import '../reporter/reporter_submit_screen.dart';
import 'bookmarks_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// The bottom-nav "Account" tab — signed-out prompt or signed-in profile,
/// driven entirely by authControllerProvider so it always reflects the
/// current session (including a silent sign-out if a stored token turns
/// out to be expired/revoked on restore).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('प्रोफाइल')),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your account. Please restart the app.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (user) => user == null ? _SignedOutView() : _SignedInView(user: user),
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Log in to save articles, like news, and join the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Log In'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
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
