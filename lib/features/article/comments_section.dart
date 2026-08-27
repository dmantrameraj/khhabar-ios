import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/comment.dart';
import '../../widgets/news_card.dart';
import '../auth/login_screen.dart';

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, slug) {
  return ref.watch(newsRepositoryProvider).getComments(slug);
});

/// The article page's comment thread — list + reply/like + a "write a
/// comment" box. Embedded at the bottom of ArticleScreen's content list.
class CommentsSection extends ConsumerStatefulWidget {
  final String slug;

  const CommentsSection({super.key, required this.slug});

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  // Local optimistic-update copy, seeded once the provider resolves.
  List<Comment>? _comments;
  final TextEditingController _newCommentController = TextEditingController();
  bool _posting = false;
  int? _replyingToId;
  final TextEditingController _replyController = TextEditingController();

  bool get _isSignedIn => ref.read(authControllerProvider).value != null;

  @override
  void dispose() {
    _newCommentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _requireLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _submit({int? parentId, required TextEditingController controller}) async {
    final text = controller.text.trim();
    if (text.isEmpty || _posting) {
      return;
    }
    if (!_isSignedIn) {
      _requireLogin();
      return;
    }

    setState(() => _posting = true);
    try {
      final posted = await ref.read(newsRepositoryProvider).postComment(widget.slug, text, parentId: parentId);
      setState(() {
        final current = List<Comment>.from(_comments ?? const []);
        _comments = parentId == null
            ? [...current, posted]
            : _updateTree(current, parentId, (c) => c.copyWith(replies: [...c.replies, posted]));
        controller.clear();
        _replyingToId = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  Future<void> _toggleLike(Comment comment) async {
    if (!_isSignedIn) {
      _requireLogin();
      return;
    }
    // Optimistic flip, corrected if the request fails.
    setState(() {
      _comments = _updateTree(
        _comments!,
        comment.id,
        (c) => c.copyWith(likedByMe: !c.likedByMe, likeCount: c.likeCount + (c.likedByMe ? -1 : 1)),
      );
    });
    try {
      await ref.read(newsRepositoryProvider).toggleCommentLike(comment.id);
    } on ApiException catch (e) {
      // Revert on failure.
      setState(() {
        _comments = _updateTree(
          _comments!,
          comment.id,
          (c) => c.copyWith(likedByMe: !c.likedByMe, likeCount: c.likeCount + (c.likedByMe ? -1 : 1)),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  List<Comment> _updateTree(List<Comment> comments, int id, Comment Function(Comment) update) {
    return comments.map((c) {
      if (c.id == id) {
        return update(c);
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _updateTree(c.replies, id, update));
      }
      return c;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commentsProvider(widget.slug));

    return async.when(
      data: (data) {
        _comments ??= data;
        return _buildContent(_comments!);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Could not load comments: $err', style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildContent(List<Comment> comments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Comments (${comments.length})'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _newCommentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onTap: () {
                    if (!_isSignedIn) {
                      _requireLogin();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                onPressed: () => _submit(controller: _newCommentController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No comments yet. Be the first to comment.', style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...comments.map((c) => _CommentTile(
                  comment: c,
                  isReply: false,
                  isReplyingHere: _replyingToId == c.id,
                  onLike: () => _toggleLike(c),
                  onReplyTap: () => setState(() => _replyingToId = _replyingToId == c.id ? null : c.id),
                  replyController: _replyController,
                  onSubmitReply: () => _submit(parentId: c.id, controller: _replyController),
                  posting: _posting,
                  onLikeReply: _toggleLike,
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final bool isReplyingHere;
  final VoidCallback onLike;
  final VoidCallback onReplyTap;
  final TextEditingController replyController;
  final VoidCallback onSubmitReply;
  final bool posting;
  final void Function(Comment) onLikeReply;

  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.isReplyingHere,
    required this.onLike,
    required this.onReplyTap,
    required this.replyController,
    required this.onSubmitReply,
    required this.posting,
    required this.onLikeReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: AppTheme.navy,
            backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
            child: comment.authorAvatar == null
                ? Text(
                    comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(formatArticleDate(comment.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: comment.likedByMe ? AppTheme.accent : Colors.grey.shade600,
                          ),
                          if (comment.likeCount > 0) ...[
                            const SizedBox(width: 3),
                            Text('${comment.likeCount}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    if (!isReply) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: onReplyTap,
                        child: Text('Reply', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                if (isReplyingHere) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: replyController,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: posting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, size: 20),
                        onPressed: onSubmitReply,
                      ),
                    ],
                  ),
                ],
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map((r) => _CommentTile(
                        comment: r,
                        isReply: true,
                        isReplyingHere: false,
                        onLike: () => onLikeReply(r),
                        onReplyTap: () {},
                        replyController: replyController,
                        onSubmitReply: () {},
                        posting: posting,
                        onLikeReply: onLikeReply,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
