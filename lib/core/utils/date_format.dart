import 'package:intl/intl.dart';

/// Matches the website's own article date format exactly
/// (application/views/articles/show.php: date('d M Y, h:i A', ...) →
/// "17 Aug 2026, 05:18 AM") — the API returns published_at as a plain
/// "Y-m-d H:i:s" string (already in IST, see Database.php's session
/// timezone fix), so this parses it as local time, not UTC.
String formatArticleDate(String publishedAt) {
  try {
    final parsed = DateTime.parse(publishedAt.replaceFirst(' ', 'T'));
    return DateFormat('d MMM yyyy, hh:mm a').format(parsed);
  } catch (_) {
    return publishedAt;
  }
}
