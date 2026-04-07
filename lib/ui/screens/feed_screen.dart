import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/moments_repository.dart'
    show CoupleMoment, MomentsRepository;
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';
import '../../widgets/moment_card.dart';
import '../../widgets/network_retry_banner.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _refreshing = false;
  int _reloadTick = 0;

  Future<void> _refreshMoments(String coupleId) async {
    if (_refreshing) return;
    final repo = context.read<MomentsRepository>();
    setState(() => _refreshing = true);
    try {
      await repo.refreshMoments(coupleId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드를 새로고침하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<AppSettings>();
    final accent = settings.accentColor;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedTitle)),
      body: user == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                NetworkRetryBanner(
                  onRetry: () => setState(() => _reloadTick++),
                ),
                Expanded(
                  child: StreamBuilder(
                    key: ValueKey('feed-user-$_reloadTick'),
                    stream: context.read<UserRepository>().watchUser(user.uid),
                    builder: (context, userSnap) {
                      final coupleId =
                          userSnap.data?.data()?['coupleId'] as String?;
                      if (coupleId == null || coupleId.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.feedConnectFirst,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }
                      return StreamBuilder<List<CoupleMoment>>(
                        stream: context.read<MomentsRepository>().watchMoments(
                          coupleId,
                        ),
                        builder: (context, mSnap) {
                          if (mSnap.hasError) {
                            return Center(child: Text('${mSnap.error}'));
                          }
                          if (!mSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final list = mSnap.data!;
                          if (list.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.dynamic_feed_rounded,
                                      size: 56,
                                      color: accent,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.feedEmptyTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.feedEmptyBody,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () => _refreshMoments(coupleId),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 24,
                              ),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                return MomentCard(
                                  coupleId: coupleId,
                                  moment: list[i],
                                  accent: accent,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
