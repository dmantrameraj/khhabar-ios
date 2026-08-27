/// A category from GET /categories or GET /categories/{slug} — top-level
/// categories carry their active subcategories in [children].
class CategoryNode {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final int? parentId;
  final List<CategoryNode> children;

  CategoryNode({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.parentId,
    this.children = const [],
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) => CategoryNode(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
        image: json['image'] as String?,
        parentId: json['parent_id'] as int?,
        children: (json['children'] as List? ?? const [])
            .map((e) => CategoryNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
