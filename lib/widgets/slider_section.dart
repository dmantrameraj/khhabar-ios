import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/url_slug.dart';
import '../data/models/home_feed.dart';
import '../features/article/article_screen.dart';

/// Admin-curated hero image carousel (Admin -> Sliders on the website) —
/// large, auto-rotating, swipeable images with dot indicators, the
/// top-of-home-screen pattern from the Dainik Bhaskar reference. Renders
/// nothing when there are no active sliders, so an admin who hasn't set
/// any up yet sees the app exactly as before.
class SliderSection extends StatefulWidget {
  final List<SliderItem> sliders;

  const SliderSection({super.key, required this.sliders});

  @override
  State<SliderSection> createState() => _SliderSectionState();
}

class _SliderSectionState extends State<SliderSection> {
  final PageController _pageController = PageController();
  Timer? _autoAdvanceTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sliders.length > 1) {
      _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) {
      return;
    }
    final next = (_page + 1) % widget.sliders.length;
    _pageController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openSlider(SliderItem slider) async {
    final link = slider.link;
    if (link == null || link.isEmpty) {
      return;
    }

    final slug = extractArticleSlug(link);
    if (slug != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(slug: slug)));
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.sliders.length,
            itemBuilder: (context, i) {
              final slider = widget.sliders[i];
              return GestureDetector(
                onTap: () => _openSlider(slider),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: slider.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey.shade300),
                      errorWidget: (c, u, e) => Container(color: Colors.grey.shade300),
                    ),
                    if (slider.title != null && slider.title!.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(
                            slider.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.sliders.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.sliders.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
