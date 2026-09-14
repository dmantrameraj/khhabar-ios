import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/user_preferences.dart';

/// "डार्क मोड" — System / Light / Dark, persisted via
/// [themeModeProvider]. A simple radio-list bottom sheet, same pattern
/// as the state picker and font-size sheet.
Future<void> openThemeModeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => const _ThemeModeSheet(),
  );
}

class _ThemeModeSheet extends ConsumerWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('डार्क मोड', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          for (final entry in const {
            ThemeMode.system: 'सिस्टम के अनुसार',
            ThemeMode.light: 'लाइट',
            ThemeMode.dark: 'डार्क',
          }.entries)
            RadioListTile<ThemeMode>(
              value: entry.key,
              groupValue: current,
              title: Text(entry.value),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).set(mode);
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
