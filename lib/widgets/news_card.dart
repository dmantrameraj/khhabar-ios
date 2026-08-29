import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/whatsapp_share.dart';
import '../data/models/news_article.dart';

/// WhatsApp's own brand green — close enough to their logo color without
/// pulling in a brand-asset SVG for a single icon.
const _whatsappGreen = Color(0xFF25D366);

/// Large hero card — top story on the home screen.
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
            if (article.featuredImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.featuredImage!,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey.shade300),
                  errorWidget: (c, u, e) =>
                      Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${article.category.name} · ${article.readingTimeMinutes} min read',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => shareToWhatsApp(articleShareText(article.title, article.slug)),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.chat, color: _whatsappGreen, size: 20),
                        ),
                      ),
                    ],
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
        trailing: IconButton(
          icon: const Icon(Icons.chat, color: _whatsappGreen, size: 22),
          tooltip: 'WhatsApp पर शेयर करें',
          onPressed: () => shareToWhatsApp(articleShareText(article.title, article.slug)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
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
