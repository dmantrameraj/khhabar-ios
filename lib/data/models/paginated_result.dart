/// Generic wrapper matching every list endpoint's `meta` shape
/// (page, per_page, total, has_next — see api-documentation.md).
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final bool hasNext;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.hasNext,
  });
}
