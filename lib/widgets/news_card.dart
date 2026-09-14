import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/whatsapp_share.dart';
import '../data/models/news_article.dart';

/// WhatsApp's own brand green, used behind the real logo glyph below.
const _whatsappGreen = Color(0xFF25D366);

/// Large hero card — top story on the home screen. Category/title read as
/// plain text ABOVE the image, image plain below — reverted from an
/// earlier overlay-on-image treatment (dark gradient scrim behind white
/// text stacked on top of the photo) per explicit request: the title
/// wasn't meant to be layered onto the image, just placed before it.
/// See also NewsFeedCard, which uses the same treatment.
class NewsHeroCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const NewsHeroCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.isBreaking)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${article.category.name} · ${article.readingTimeMinutes} min read',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: article.featuredImage != null
                  ? CachedNetworkImage(
                      imageUrl: article.featuredImage!,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey.shade300),
                      errorWidget: (c, u, e) =>
                          Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    )
                  : Container(color: AppTheme.navy),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => shareToWhatsApp(articleShareText(article.title, article.slug)),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: FaIcon(FontAwesomeIcons.whatsapp, color: _whatsappGreen, size: 20),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Share.share(articleShareText(article.title, article.slug)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.share, color: Colors.grey.shade700, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width card for a continuous feed (Home's "ताजा खबर") — same
/// title-before-image treatment as NewsHeroCard, just a shorter image and
/// no "LIVE" badge, since breaking-ness is already called out by the
/// hero card at the top of the feed.
class NewsFeedCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const NewsFeedCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${article.category.name} · ${article.author.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: article.featuredImage != null
                  ? CachedNetworkImage(
                      imageUrl: article.featuredImage!,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey.shade300),
                      errorWidget: (c, u, e) =>
                          Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    )
                  : Container(color: AppTheme.navy),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: _whatsappGreen, size: 20),
                    tooltip: 'WhatsApp पर शेयर करें',
                    onPressed: () => shareToWhatsApp(articleShareText(article.title, article.slug)),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.grey.shade700, size: 18),
                    tooltip: 'और शेयर विकल्प',
                    onPressed: () => Share.share(articleShareText(article.title, article.slug)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal-list row — used for the home feed's "latest news"
/// list, category listings, and search results.
class NewsListTile extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const NewsListTile({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: article.featuredImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: article.featuredImage!,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(width: 80, height: 60, color: Colors.grey.shade300),
                  errorWidget: (c, u, e) => Container(width: 80, height: 60, color: Colors.grey.shade300),
                ),
              )
            : Container(
                width: 80,
                height: 60,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported),
              ),
        title: Text(
          article.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${article.category.name} · ${article.author.name}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: _whatsappGreen, size: 22),
              tooltip: 'WhatsApp पर शेयर करें',
              onPressed: () => shareToWhatsApp(articleShareText(article.title, article.slug)),
            ),
            IconButton(
              icon: Icon(Icons.share, color: Colors.grey.shade700, size: 20),
              tooltip: 'और शेयर विकल्प',
              onPressed: () => Share.share(articleShareText(article.title, article.slug)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered horizontal card for the trending strip.
class TrendingCard extends StatelessWidget {
  final NewsArticle article;
  final int rank;
  final VoidCallback onTap;

  const TrendingCard({super.key, required this.article, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.accent,
              child: Text(
                '$rank',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section title used above every horizontal list / feed section.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // AppTheme.navy is a near-black — fine as text on the light theme's
    // pale background, but nearly invisible on the dark theme's own
    // near-black background. Follow the active theme's own text color
    // instead of hardcoding the brand navy here.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppTheme.navy,
        ),
      ),
    );
  }
}

/// Shared loading / error / empty states — every screen that hits the API
/// uses this instead of hand-rolling its own (Phase 24 requirement).
class AsyncStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AsyncStateView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(error.toString(), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: onRetry, child: const Text('Retry'))),
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String message;

  const EmptyStateView({super.key, this.message = 'No news found.'});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(child: Text(message, style: TextStyle(color: Colors.grey.shade600))),
      ],
    );
  }
}
