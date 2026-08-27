/// Pulls the article slug out of a khhabar.com article URL
/// ("https://khhabar.com/news/some-slug" -> "some-slug"), or null if the
/// URL isn't an article link. Shared by PushService (notification taps)
/// and DeepLinkService (App Links / Universal Links) — both need to answer
/// the same question: "does this URL point at an article, and which one?"
String? extractArticleSlug(String? url) {
  if (url == null) {
    return null;
  }
  final match = RegExp(r'/news/([^/?#]+)').firstMatch(url);
  return match?.group(1);
}
