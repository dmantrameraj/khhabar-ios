import 'package:flutter/material.dart';

import '../../widgets/category_feed_list.dart';

/// Articles within one category (or its subcategories), with infinite
/// scroll — matches the website's own category page pagination. The
/// actual list/pagination logic lives in CategoryFeedList, shared with
/// Home's swipeable category tabs.
class CategoryDetailScreen extends StatelessWidget {
  final String slug;
  final String name;

  const CategoryDetailScreen({super.key, required this.slug, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: CategoryFeedList(slug: slug),
    );
  }
}
