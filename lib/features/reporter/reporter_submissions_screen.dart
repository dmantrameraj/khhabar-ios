import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reporter_submission.dart';
import '../../widgets/news_card.dart';
import 'reporter_submit_screen.dart';

final _mySubmissionsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(reporterRepositoryProvider).mySubmissions();
});

/// A reporter's own filed stories and what happened to each — status
/// badge + rejection reason when there is one. This is the only feedback
/// loop a reporter gets after filing a story from the app (there's no
/// push notification for approval/rejection yet), so it has to be easy
/// to reach and refresh.
class ReporterSubmissionsScreen extends ConsumerWidget {
  const ReporterSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_mySubmissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('मेरी खबरें')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ReporterSubmitScreen()),
          );
          if (submitted == true) {
            ref.invalidate(_mySubmissionsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('नई खबर'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_mySubmissionsProvider.future),
        child: async.when(
          data: (result) => result.items.isEmpty
              ? const EmptyStateView(message: 'आपने अभी तक कोई खबर नहीं भेजी है।')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: result.items.length,
                  itemBuilder: (context, i) => _SubmissionCard(item: result.items[i]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncStateView(error: err, onRetry: () => ref.invalidate(_mySubmissionsProvider)),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final ReporterSubmission item;

  const _SubmissionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.featuredImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: item.featuredImage!,
                  width: 70,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(width: 70, height: 60, color: Colors.grey.shade300),
                  errorWidget: (c, u, e) => Container(width: 70, height: 60, color: Colors.grey.shade300),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (item.categoryName != null)
                    Text(item.categoryName!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 6),
                  _StatusChip(status: item.status),
                  if (item.status == 'rejected' && item.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.rejectionReason!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('समीक्षा में', Colors.orange),
      'approved' => ('स्वीकृत', Colors.blue),
      'published' => ('प्रकाशित', Colors.green),
      'rejected' => ('अस्वीकृत', Colors.red),
      'draft' => ('ड्राफ्ट', Colors.grey),
      _ => (status, AppTheme.navy),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
