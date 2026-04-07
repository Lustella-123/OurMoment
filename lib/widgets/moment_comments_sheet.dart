import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/moments_repository.dart';

Future<void> showMomentCommentsSheet({
  required BuildContext context,
  required String coupleId,
  required String momentId,
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _CommentsSheetBody(
          coupleId: coupleId,
          momentId: momentId,
          accent: accent,
        ),
      );
    },
  );
}

class _CommentsSheetBody extends StatefulWidget {
  const _CommentsSheetBody({
    required this.coupleId,
    required this.momentId,
    required this.accent,
  });

  final String coupleId;
  final String momentId;
  final Color accent;

  @override
  State<_CommentsSheetBody> createState() => _CommentsSheetBodyState();
}

class _CommentsSheetBodyState extends State<_CommentsSheetBody> {
  final _ctrl = TextEditingController();
  String? _editingCommentId;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<MomentsRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final locale = Localizations.localeOf(context).toString();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.momentCommentsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<MomentComment>>(
                stream: repo.watchComments(widget.coupleId, widget.momentId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return ListView(
                      controller: scrollCtrl,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          l10n.feedEmptyBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final mine = uid == c.authorUid;
                      final timeText = DateFormat(
                        'yyyy.MM.dd HH:mm',
                        locale,
                      ).format(c.createdAt);
                      final safeName = c.authorName.trim().isNotEmpty
                          ? c.authorName.trim()
                          : (mine ? '나' : '상대');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              backgroundImage: c.authorPhotoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(c.authorPhotoUrl)
                                  : null,
                              child: c.authorPhotoUrl.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          safeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        timeText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.text),
                                ],
                              ),
                            ),
                            if (mine)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                tooltip: '댓글 메뉴',
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    setState(() {
                                      _editingCommentId = c.id;
                                      _ctrl.text = c.text;
                                    });
                                    return;
                                  }
                                  await repo.deleteComment(
                                    widget.coupleId,
                                    widget.momentId,
                                    c.id,
                                  );
                                  if (!mounted) return;
                                  if (_editingCommentId == c.id) {
                                    setState(() => _editingCommentId = null);
                                    _ctrl.clear();
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('수정'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18),
                                        SizedBox(width: 8),
                                        Text('삭제'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_editingCommentId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '댓글 수정 중',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _editingCommentId = null);
                        _ctrl.clear();
                      },
                      child: const Text('취소'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: _editingCommentId == null
                            ? l10n.momentCommentHint
                            : '댓글 수정 내용',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(repo),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _send(repo),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      _editingCommentId == null
                          ? Icons.send_rounded
                          : Icons.check_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(MomentsRepository repo) async {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    if (_editingCommentId == null) {
      await repo.addComment(widget.coupleId, widget.momentId, t);
    } else {
      await repo.updateComment(
        coupleId: widget.coupleId,
        momentId: widget.momentId,
        commentId: _editingCommentId!,
        text: t,
      );
    }
    if (!mounted) return;
    setState(() => _editingCommentId = null);
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }
}
