import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/location_repository.dart';

/// Distinguishes "picker dismissed without choosing" from "explicitly
/// chose All India" (both would otherwise pop null from the sheet).
const _cancelled = StateOption(id: -1, name: '__cancelled__');

/// Opens the state-picker bottom sheet and applies the choice to
/// [selectedStateProvider]. Shared by Home's AppBar location action and
/// Account's "अपना राज्य चुनें" menu item — one picker, two entry points.
///
/// App-side location filtering is **state-only** by design (see
/// CLAUDE.md — the app's news card data only ever surfaces state, not
/// city, even though the backend's location hierarchy goes 5 levels
/// deep to city); this doesn't do city-level selection.
Future<void> openLocationPicker(BuildContext context, WidgetRef ref) async {
  final selected = await showModalBottomSheet<StateOption?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const StatePickerSheet(),
  );

  if (selected != _cancelled) {
    ref.read(selectedStateProvider.notifier).state = selected;
  }
}

class StatePickerSheet extends ConsumerStatefulWidget {
  const StatePickerSheet({super.key});

  @override
  ConsumerState<StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends ConsumerState<StatePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<StateOption>? _states;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final states = await ref.read(locationRepositoryProvider).getStates();
      if (mounted) {
        setState(() => _states = states);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    final filtered = states == null
        ? const <StateOption>[]
        : states.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('अपना राज्य चुनें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(_cancelled),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'राज्य खोजें...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _error != null
                ? Center(child: Text('राज्यों की सूची लोड नहीं हो सकी।\n$_error', textAlign: TextAlign.center))
                : states == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollController,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.public, color: AppTheme.accent),
                            title: const Text('सभी राज्य (All India)'),
                            onTap: () => Navigator.of(context).pop(null),
                          ),
                          const Divider(height: 1),
                          ...filtered.map(
                            (s) => ListTile(
                              title: Text(s.name),
                              onTap: () => Navigator.of(context).pop(s),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
