import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.text),
                        trailing: mine
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => repo.deleteComment(
                                  widget.coupleId,
                                  widget.momentId,
                                  c.id,
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
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
                        hintText: l10n.momentCommentHint,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(repo, l10n),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _send(repo, l10n),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(MomentsRepository repo, AppLocalizations l10n) async {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    await repo.addComment(widget.coupleId, widget.momentId, t);
    if (!mounted) return;
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }
}
