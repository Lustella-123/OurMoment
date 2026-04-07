import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/couple_repository.dart';
import '../../services/user_repository.dart';

/// 연결 직후 한 번: 연애 시작일·결혼일은 각각 선택(둘 다 비워도 됨)
class MilestonesOnboardingLayer extends StatefulWidget {
  const MilestonesOnboardingLayer({super.key, required this.child});

  final Widget child;

  @override
  State<MilestonesOnboardingLayer> createState() =>
      _MilestonesOnboardingLayerState();
}

class _MilestonesOnboardingLayerState extends State<MilestonesOnboardingLayer> {
  String? _promptCoupleId;
  bool _promptScheduled = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return widget.child;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().watchUser(user.uid),
      builder: (context, userSnap) {
        final cid = userSnap.data?.data()?['coupleId'] as String?;
        if (cid == null || cid.isEmpty) {
          _promptCoupleId = null;
          _promptScheduled = false;
          return widget.child;
        }

        if (_promptCoupleId != cid) {
          _promptCoupleId = cid;
          _promptScheduled = false;
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: context.read<CoupleRepository>().watchCouple(cid),
          builder: (context, cSnap) {
            if (!cSnap.hasData || !cSnap.data!.exists) return widget.child;
            final done =
                cSnap.data!.data()?['milestonesOnboardingDone'] == true;
            if (done) {
              _promptScheduled = false;
              return widget.child;
            }
            if (!_promptScheduled) {
              _promptScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                unawaited(_showSheet(context, cid));
              });
            }
            return widget.child;
          },
        );
      },
    );
  }

  Future<void> _showSheet(BuildContext context, String coupleId) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.yMMMMd(locale);

    DateTime? rel;
    DateTime? wed;

    final coupleRepo = context.read<CoupleRepository>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.paddingOf(ctx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.milestonesOnboardingTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.milestonesOnboardingBody,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsRelationshipStart),
                    subtitle: Text(rel != null ? df.format(rel!) : l10n.settingsTapToSet),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: rel ?? DateTime.now(),
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setModal(() => rel = d);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsWeddingDate),
                    subtitle: Text(wed != null ? df.format(wed!) : l10n.settingsTapToSet),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: wed ?? DateTime.now(),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setModal(() => wed = d);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await coupleRepo.markMilestonesOnboardingDone(coupleId);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(l10n.milestonesSkip),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (rel != null) {
                              await coupleRepo.updateMilestones(
                                coupleId: coupleId,
                                relationshipStart: rel,
                              );
                            }
                            if (wed != null) {
                              await coupleRepo.updateMilestones(
                                coupleId: coupleId,
                                weddingDate: wed,
                              );
                            }
                            await coupleRepo.markMilestonesOnboardingDone(coupleId);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(l10n.milestonesConfirm),
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
    );
  }
}
