import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/news_card.dart';

final _earningsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(reporterRepositoryProvider).getEarnings();
});

/// A reporter's commission summary — pending vs paid, and how many
/// articles have earned something. Same numbers as the website's own
/// reporter dashboard (ContentEarningModel::summaryForUser()); an
/// earning is credited the moment an admin approves/publishes an
/// article, regardless of whether it was filed from the app or the
/// website — this screen only ever displays that, never computes it.
class ReporterEarningsScreen extends ConsumerWidget {
  const ReporterEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_earningsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('मेरी कमाई')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_earningsProvider.future),
        child: async.when(
          data: (e) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _AmountCard(
                      label: 'बकाया राशि',
                      amount: e.pendingAmount,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountCard(
                      label: 'भुगतान की गई',
                      amount: e.paidAmount,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.article_outlined, color: AppTheme.navy),
                  title: const Text('कुल भुगतान योग्य खबरें'),
                  trailing: Text(
                    '${e.totalArticles}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'खबर स्वीकृत/प्रकाशित होने पर ही कमाई जुड़ती है — भेजी गई हर खबर पर कमाई नहीं मिलती। भुगतान एडमिन द्वारा तय समय पर किया जाता है।',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(_earningsProvider)),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
