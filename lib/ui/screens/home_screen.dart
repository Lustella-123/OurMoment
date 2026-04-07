import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/couple_repository.dart';
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';
import '../../widgets/ad_banner_slot.dart';
import '../../widgets/love_temperature_card.dart';
import '../../widgets/network_retry_banner.dart';
import 'diary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _reloadTick = 0;

  Stream<_HomeVm> _watchHomeVm({
    required String myUid,
    required String meLabelFallback,
    required String partnerLabelFallback,
    required String ddayNotSetLabel,
  }) {
    final userRepo = context.read<UserRepository>();
    final coupleRepo = context.read<CoupleRepository>();
    return userRepo.watchUser(myUid).asyncExpand((userSnap) {
      final myData = userSnap.data() ?? const <String, dynamic>{};
      final myName = (myData['displayName'] as String?)?.trim();
      final myLabel = (myName != null && myName.isNotEmpty)
          ? myName
          : meLabelFallback;
      final coupleId = myData['coupleId'] as String?;
      if (coupleId == null || coupleId.isEmpty) {
        return Stream.value(
          _HomeVm(
            myLabel: myLabel,
            partnerLabel: partnerLabelFallback,
            togetherLabel: ddayNotSetLabel,
            weddingLabel: null,
            loveDegrees: 0,
          ),
        );
      }
      return coupleRepo.watchCouple(coupleId).asyncExpand((coupleSnap) {
        final cd = coupleSnap.data() ?? const <String, dynamic>{};
        final members = List<String>.from(
          cd['memberIds'] as List<dynamic>? ?? const [],
        );
        final partnerUid = members.length == 2
            ? members.firstWhere((id) => id != myUid, orElse: () => '')
            : '';
        final created = cd['createdAt'] as Timestamp?;
        final relStart = cd['relationshipStart'] as Timestamp? ?? created;
        final wedding = cd['weddingDate'] as Timestamp?;
        final love = ((cd['loveTemperature'] as num?)?.toInt() ?? 0).clamp(
          0,
          kLoveTemperatureMax,
        );
        final togetherLabel = _ddayLabel(relStart, ddayNotSetLabel);
        final weddingLabel = wedding == null
            ? null
            : _ddayLabel(wedding, ddayNotSetLabel);
        if (partnerUid.isEmpty) {
          return Stream.value(
            _HomeVm(
              myLabel: myLabel,
              partnerLabel: partnerLabelFallback,
              togetherLabel: togetherLabel,
              weddingLabel: weddingLabel,
              loveDegrees: love,
            ),
          );
        }
        return userRepo.watchUser(partnerUid).map((partnerSnap) {
          final pn = (partnerSnap.data()?['displayName'] as String?)?.trim();
          final partnerLabel = (pn != null && pn.isNotEmpty)
              ? pn
              : partnerLabelFallback;
          return _HomeVm(
            myLabel: myLabel,
            partnerLabel: partnerLabel,
            togetherLabel: togetherLabel,
            weddingLabel: weddingLabel,
            loveDegrees: love,
          );
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<AppSettings>();
    final accent = settings.accentColor;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: user == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                NetworkRetryBanner(
                  onRetry: () => setState(() => _reloadTick++),
                ),
                Expanded(
                  child: StreamBuilder<_HomeVm>(
                    key: ValueKey(_reloadTick),
                    stream: _watchHomeVm(
                      myUid: user.uid,
                      meLabelFallback: l10n.homeMe,
                      partnerLabelFallback: l10n.homePartnerPlaceholder,
                      ddayNotSetLabel: l10n.homeDdayNotSet,
                    ),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return _HomeError(
                          message: snap.error.toString(),
                          settings: settings,
                        );
                      }
                      if (!snap.hasData) {
                        return _HomeLoading(settings: settings);
                      }
                      final vm = snap.data!;
                      return _HomeBody(
                        accent: accent,
                        l10n: l10n,
                        settings: settings,
                        togetherLabel: vm.togetherLabel,
                        weddingLabel: vm.weddingLabel,
                        loveDegrees: vm.loveDegrees,
                        myLabel: vm.myLabel,
                        partnerLabel: vm.partnerLabel,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HomeVm {
  const _HomeVm({
    required this.myLabel,
    required this.partnerLabel,
    required this.togetherLabel,
    required this.weddingLabel,
    required this.loveDegrees,
  });

  final String myLabel;
  final String partnerLabel;
  final String togetherLabel;
  final String? weddingLabel;
  final int loveDegrees;
}

String _ddayLabel(Timestamp? t, String ddayNotSetLabel) {
  if (t == null) return ddayNotSetLabel;
  final start = DateUtils.dateOnly(t.toDate());
  final today = DateUtils.dateOnly(DateTime.now());
  final d = today.difference(start).inDays;
  final days = d < 0 ? 0 : d;
  return 'D+$days';
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: Center(child: CircularProgressIndicator())),
        Center(child: AdBannerSlot(settings: settings)),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.settings});

  final String message;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
        Center(child: AdBannerSlot(settings: settings)),
      ],
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.accent,
    required this.l10n,
    required this.settings,
    required this.togetherLabel,
    required this.weddingLabel,
    required this.loveDegrees,
    required this.myLabel,
    required this.partnerLabel,
  });

  final Color accent;
  final AppLocalizations l10n;
  final AppSettings settings;
  final String togetherLabel;
  final String? weddingLabel;
  final int loveDegrees;
  final String myLabel;
  final String partnerLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 8),
              _CoupleHeader(
                accent: accent,
                myLabel: myLabel,
                partnerLabel: partnerLabel,
              ),
              const SizedBox(height: 20),
              _DdayRow(
                accent: accent,
                l10n: l10n,
                togetherTitle: togetherLabel,
                weddingTitle: weddingLabel,
              ),
              const SizedBox(height: 24),
              LoveTemperatureCard(degrees: loveDegrees, accent: accent),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      unawaited(
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const DiaryScreen(),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.photo_camera_rounded,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              l10n.diaryPhotoPick,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(child: AdBannerSlot(settings: settings)),
      ],
    );
  }
}

class _CoupleHeader extends StatelessWidget {
  const _CoupleHeader({
    required this.accent,
    required this.myLabel,
    required this.partnerLabel,
  });

  final Color accent;
  final String myLabel;
  final String partnerLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AvatarPlaceholder(label: myLabel, accent: accent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.favorite_rounded, color: accent, size: 36),
          ),
          _AvatarPlaceholder(label: partnerLabel, accent: accent),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: accent.withValues(alpha: 0.2),
          child: Icon(Icons.person_rounded, size: 48, color: accent),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DdayRow extends StatelessWidget {
  const _DdayRow({
    required this.accent,
    required this.l10n,
    required this.togetherTitle,
    required this.weddingTitle,
  });

  final Color accent;
  final AppLocalizations l10n;
  final String togetherTitle;
  final String? weddingTitle;

  @override
  Widget build(BuildContext context) {
    final showWedding = weddingTitle != null && weddingTitle!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _DdayChip(
              title: togetherTitle,
              subtitle: l10n.homeTogetherDays,
              accent: accent,
            ),
          ),
          if (showWedding) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _DdayChip(
                title: weddingTitle!,
                subtitle: l10n.homeWeddingDday,
                accent: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DdayChip extends StatelessWidget {
  const _DdayChip({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
