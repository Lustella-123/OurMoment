import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../services/moments_repository.dart';
import 'moment_comments_sheet.dart';

class MomentCard extends StatefulWidget {
  const MomentCard({
    super.key,
    required this.coupleId,
    required this.moment,
    required this.accent,
  });

  final String coupleId;
  final CoupleMoment moment;
  final Color accent;

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<MomentsRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAuthor = uid != null && uid == widget.moment.authorUid;
    final locale = Localizations.localeOf(context).toString();
    final timeText = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(widget.moment.createdAt);
    final urls = widget.moment.imageUrls;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: widget.accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (urls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: urls.length,
                      onPageChanged: (i) {
                        if (!mounted) return;
                        setState(() => _page = i);
                      },
                      itemBuilder: (ctx, i) {
                        return CachedNetworkImage(
                          imageUrl: urls[i],
                          fit: BoxFit.cover,
                          placeholder: (ctx, _) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                    if (urls.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            urls.length,
                            (i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: _page == i
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.moment.caption.isNotEmpty)
                        Text(
                          widget.moment.caption,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v != 'delete') return;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          content: Text(l10n.momentDeleteConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.commonCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.commonDelete),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        try {
                          await repo.deleteMoment(
                            widget.coupleId,
                            widget.moment,
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('삭제에 실패했어요. 다시 시도해 주세요.'),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.momentDelete),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                StreamBuilder<bool>(
                  stream: repo.watchUserLiked(
                    widget.coupleId,
                    widget.moment.id,
                  ),
                  builder: (context, snap) {
                    final liked = snap.data ?? false;
                    return IconButton(
                      onPressed: () async {
                        try {
                          await repo.toggleLike(
                            widget.coupleId,
                            widget.moment.id,
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('좋아요 처리에 실패했어요.')),
                          );
                        }
                      },
                      icon: Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: liked ? widget.accent : null,
                      ),
                    );
                  },
                ),
                Text(
                  l10n.momentLikeCount(widget.moment.likeCount),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                IconButton(
                  onPressed: () {
                    unawaited(
                      showMomentCommentsSheet(
                        context: context,
                        coupleId: widget.coupleId,
                        momentId: widget.moment.id,
                        accent: widget.accent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
