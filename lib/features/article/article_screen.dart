import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/feature_flags.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/html_to_text.dart';
import '../../core/utils/whatsapp_share.dart';
import '../../data/models/article_detail.dart';
import '../../widgets/article_narration_player.dart';
import '../../widgets/news_card.dart';
import '../auth/login_screen.dart';
import '../search/search_screen.dart';
import 'comments_section.dart';

final articleProvider = FutureProvider.family<ArticleDetail, String>((ref, slug) {
  return ref.watch(newsRepositoryProvider).getArticle(slug);
});

/// Full article detail screen — native rendering (not a WebView), reached
/// by tapping any article card, a deep link, or a push notification.
class ArticleScreen extends ConsumerStatefulWidget {
  final String slug;

  const ArticleScreen({super.key, required this.slug});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  // Local optimistic-update copy of the loaded article — seeded from the
  // provider once it resolves, then mutated directly after a successful
  // like/bookmark toggle so the icon flips instantly without a refetch.
  ArticleDetail? _detail;
  bool _togglingLike = false;
  bool _togglingBookmark = false;

  bool get _isSignedIn => ref.read(authControllerProvider).value != null;

  void _requireLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _toggleLike() async {
    if (_detail == null || _togglingLike) {
      return;
    }
    if (!_isSignedIn) {
      _requireLogin();
      return;
    }

    setState(() => _togglingLike = true);
    try {
      final (liked, likesCount) = await ref.read(newsRepositoryProvider).toggleLike(widget.slug);
      if (mounted) {
        setState(() => _detail = _detail!.copyWith(liked: liked, likesCount: likesCount));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _togglingLike = false);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_detail == null || _togglingBookmark) {
      return;
    }
    if (!_isSignedIn) {
      _requireLogin();
      return;
    }

    setState(() => _togglingBookmark = true);
    try {
      final bookmarked = await ref.read(newsRepositoryProvider).toggleBookmark(widget.slug);
      if (mounted) {
        setState(() {
          _detail = _detail!.copyWith(bookmarked: bookmarked);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bookmarked ? 'Saved to your bookmarks.' : 'Removed from your bookmarks.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _togglingBookmark = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seeds _detail as soon as the provider resolves, via a rebuild-safe
    // setState (ref.listen's callback runs after the build phase, unlike
    // the `data:` branch of asyncDetail.when() below — mutating _detail
    // there without setState left the AppBar's action icons (which key
    // off `_detail != null`) permanently invisible, since the AppBar is
    // built from the *same* build() call before that assignment lands
    // and nothing was ever scheduling the follow-up rebuild that would
    // have picked it up. Confirmed via a live run: like/bookmark/share
    // never appeared even once real content was loaded and rendered.
    ref.listen(articleProvider(widget.slug), (previous, next) {
      next.whenData((d) {
        if (_detail == null && mounted) {
          setState(() => _detail = d);
        }
      });
    });
    final asyncDetail = ref.watch(articleProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_detail != null) ...[
            if (FeatureFlags.likeButtonEnabled)
              IconButton(
                tooltip: _detail!.liked ? 'Unlike' : 'Like',
                icon: _togglingLike
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _detail!.liked ? Icons.favorite : Icons.favorite_border,
                        color: _detail!.liked ? AppTheme.accent : null,
                      ),
                onPressed: _toggleLike,
              ),
            IconButton(
              tooltip: _detail!.bookmarked ? 'Remove bookmark' : 'Save article',
              icon: _togglingBookmark
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_detail!.bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _toggleBookmark,
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
              tooltip: 'WhatsApp पर शेयर करें',
              onPressed: () => shareToWhatsApp(articleShareText(_detail!.article.title, _detail!.article.slug)),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'और शेयर विकल्प',
              onPressed: () => Share.share(articleShareText(_detail!.article.title, _detail!.article.slug)),
            ),
          ],
        ],
      ),
      body: asyncDetail.when(
        data: (d) {
          _detail ??= d;
          return _ArticleContent(detail: _detail!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          error: err,
          onRetry: () {
            setState(() => _detail = null);
            ref.invalidate(articleProvider(widget.slug));
          },
        ),
      ),
    );
  }
}

class _ArticleContent extends StatelessWidget {
  final ArticleDetail detail;

  const _ArticleContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final a = detail.article;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Category + headline as plain text ABOVE the featured image —
        // per explicit request, replacing an earlier overlay-on-image
        // treatment (dark gradient scrim behind white text stacked on
        // top of the photo). Reverted because it wasn't what was wanted:
        // the title now reads before the image, not layered onto it.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.category.name.toUpperCase(),
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (a.featuredImage != null)
          CachedNetworkImage(
            imageUrl: a.featuredImage!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(height: 220, color: Colors.grey.shade300),
            errorWidget: (c, u, e) => Container(height: 220, color: Colors.grey.shade300),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.subHeading != null) ...[
                Text(a.subHeading!, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('By ${a.author.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(formatArticleDate(a.publishedAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text('${a.readingTimeMinutes} min read', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text('${a.viewsCount} views', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  if (FeatureFlags.likeButtonEnabled)
                    Text('${a.likesCount} likes', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const Divider(height: 32),
              ArticleNarrationPlayer(plainText: htmlToPlainText(detail.content)),
              Html(
                data: detail.content,
                style: {
                  'body': Style(margin: Margins.zero, fontSize: FontSize(15), lineHeight: LineHeight(1.6)),
                },
                // A reporter/editor can splice photos mid-article (see
                // ReporterApiController::buildContentHtml() and CKEditor on
                // the website) as a lone <img> inside its own <p>. Styling
                // 'img' with `Width(double.infinity)` (the previous
                // approach) reads like ordinary CSS but isn't: flutter_html
                // 3.0.0-beta.2's CssBoxWidget takes that value as a literal
                // *minWidth* constraint, not "fill available width", which
                // throws "BoxConstraints forces an infinite width" the
                // moment such an image is laid out — silently blanking the
                // ENTIRE article body below it in a release build (no error
                // shown; confirmed live via a real published article: only
                // the header/title/meta rendered, nothing else). Rendering
                // <img> ourselves via this extension — same
                // CachedNetworkImage used everywhere else in the app, sized
                // to an explicit finite width — sidesteps that broken path
                // entirely rather than fighting flutter_html's CSS engine.
                extensions: [
                  ImageExtension(
                    builder: (ctx) {
                      final src = ctx.attributes['src'];
                      if (src == null || src.isEmpty) return const SizedBox.shrink();
                      final width = MediaQuery.of(ctx.buildContext!).size.width - 32;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: src,
                            width: width,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(height: 200, width: width, color: Colors.grey.shade300),
                            errorWidget: (c, u, e) => const SizedBox.shrink(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (detail.media.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: detail.media.length,
                  itemBuilder: (context, i) {
                    final m = detail.media[i];
                    if (m.type != 'image') {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.play_circle_outline, size: 40),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: m.url, fit: BoxFit.cover),
                    );
                  },
                ),
              ],
              if (detail.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  children: detail.tags
                      .map(
                        (t) => ActionChip(
                          label: Text(t),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: t)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        if (detail.related.isNotEmpty) ...[
          const SectionHeader(title: 'Related News'),
          ...detail.related.map(
            (r) => Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArticleScreen(slug: r.slug)),
                ),
                leading: r.featuredImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: r.featuredImage!,
                          width: 70,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : null,
                title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
        const Divider(height: 32),
        CommentsSection(slug: a.slug),
      ],
    );
  }
}
