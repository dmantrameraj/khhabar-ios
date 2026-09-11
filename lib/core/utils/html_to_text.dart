/// Strips an article body's HTML down to plain, readable text — the
/// app-side equivalent of the website narration player reading
/// `container.textContent` off the rendered DOM (see public/assets/js/
/// narration.js). Doesn't need to be a full HTML parser: article content
/// only ever comes from the CMS's own CKEditor output (or the reporter
/// API's own escape-then-<p>-wrap — see ReporterApiController::
/// buildContentHtml()), never arbitrary third-party markup.
String htmlToPlainText(String html) {
  var text = html
      // Block-level boundaries become sentence/paragraph breaks so TTS
      // pauses naturally between them instead of running everything
      // together.
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\s*/(p|div|li|h[1-6])\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();

  return text;
}
