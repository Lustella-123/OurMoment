import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/moments_repository.dart';

/// 피드용 폴라로이드 카드 — 사진 개수에 따라 그리드로 분할합니다.
class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.coupleId,
    required this.moment,
  });

  final String coupleId;
  final CoupleMoment moment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<MomentsRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAuthor = uid != null && uid == moment.authorUid;
    final locale = Localizations.localeOf(context).toString();
    final timeText = DateFormat.yMMMd(locale).add_Hm().format(moment.createdAt);
    final urls = moment.imageUrls;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _MomentPhotoCollage(urls: urls),
          ),
          const SizedBox(height: 12),
          if (moment.caption.trim().isNotEmpty)
            Text(
              moment.caption.trim(),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  timeText,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
              if (isAuthor)
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text(
                          l10n.momentDelete,
                          style: const TextStyle(color: Colors.black),
                        ),
                        content: Text(
                          l10n.momentDeleteConfirm,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.commonCancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      try {
                        await repo.deleteMoment(coupleId, moment);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('삭제에 실패했어요. 다시 시도해 주세요.')),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.commonDelete, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentPhotoCollage extends StatelessWidget {
  const _MomentPhotoCollage({required this.urls});

  final List<String> urls;

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade600, size: 40),
        ),
      );
    }

    Widget cell(String url) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, prog) {
          if (prog == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => ColoredBox(
          color: const Color(0xFFEEEEEE),
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
        ),
      );
    }

    if (urls.length == 1) {
      return cell(urls[0]);
    }
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: cell(urls[0])),
          const SizedBox(width: _gap),
          Expanded(child: cell(urls[1])),
        ],
      );
    }
    if (urls.length == 3) {
      return Column(
        children: [
          Expanded(flex: 2, child: cell(urls[0])),
          const SizedBox(height: _gap),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: cell(urls[1])),
                const SizedBox(width: _gap),
                Expanded(child: cell(urls[2])),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _gap,
        mainAxisSpacing: _gap,
        childAspectRatio: 1,
      ),
      itemCount: urls.length,
      itemBuilder: (context, i) => cell(urls[i]),
    );
  }
}
