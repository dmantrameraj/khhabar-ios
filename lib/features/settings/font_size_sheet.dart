import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/user_preferences.dart';

/// "आर्टिकल फॉण्ट साइज़" — छोटा/मध्यम/बड़ा, persisted via
/// [articleFontScaleProvider] and read by `ArticleScreen`'s `Html`
/// widget (article body text only — this is deliberately not a global
/// UI text-scale toggle, just how big the article you're reading looks).
Future<void> openFontSizeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => const _FontSizeSheet(),
  );
}

class _FontSizeSheet extends ConsumerWidget {
  const _FontSizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(articleFontScaleProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('आर्टिकल फॉण्ट साइज़', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          for (final scale in ArticleFontScale.values)
            RadioListTile<ArticleFontScale>(
              value: scale,
              groupValue: current,
              title: Text(scale.label, style: TextStyle(fontSize: scale.size)),
              subtitle: const Text('खबर पढ़ने में ऐसी दिखेगी'),
              onChanged: (value) {
                if (value != null) {
                  ref.read(articleFontScaleProvider.notifier).set(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
