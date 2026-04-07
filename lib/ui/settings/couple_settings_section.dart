import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/couple_repository.dart';
import '../../services/user_repository.dart';

/// 설정 — 연애 시작일, 결혼 기념일 (이름은 프로필)
class CoupleSettingsSection extends StatelessWidget {
  const CoupleSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().watchUser(user.uid),
      builder: (context, userSnap) {
        final coupleId = userSnap.data?.data()?['coupleId'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsCoupleSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (coupleId == null || coupleId.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.settingsCoupleNotPaired,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: context.read<CoupleRepository>().watchCouple(coupleId),
                builder: (context, cSnap) {
                  if (!cSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final d = cSnap.data!.data();
                  final rel = d?['relationshipStart'] as Timestamp?;
                  final wed = d?['weddingDate'] as Timestamp?;
                  final locale = Localizations.localeOf(context).toString();
                  final df = DateFormat.yMMMMd(locale);

                  return Column(
                    children: [
                      ListTile(
                        title: Text(l10n.settingsRelationshipStart),
                        subtitle: Text(
                          rel != null ? df.format(rel.toDate()) : l10n.settingsTapToSet,
                        ),
                        onTap: () => _pickRelationshipStart(
                          context,
                          coupleId,
                          rel,
                        ),
                        trailing: rel != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => context
                                    .read<CoupleRepository>()
                                    .updateMilestones(
                                      coupleId: coupleId,
                                      clearRelationshipStart: true,
                                    ),
                              )
                            : null,
                      ),
                      ListTile(
                        title: Text(l10n.settingsWeddingDate),
                        subtitle: Text(
                          wed != null ? df.format(wed.toDate()) : l10n.settingsTapToSet,
                        ),
                        onTap: () => _pickWedding(context, coupleId, wed),
                        trailing: wed != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => context
                                    .read<CoupleRepository>()
                                    .updateMilestones(
                                      coupleId: coupleId,
                                      clearWeddingDate: true,
                                    ),
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickRelationshipStart(
    BuildContext context,
    String coupleId,
    Timestamp? current,
  ) async {
    final initial = current?.toDate() ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (d != null && context.mounted) {
      await context.read<CoupleRepository>().updateMilestones(
            coupleId: coupleId,
            relationshipStart: d,
          );
    }
  }

  Future<void> _pickWedding(
    BuildContext context,
    String coupleId,
    Timestamp? current,
  ) async {
    final initial = current?.toDate() ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (d != null && context.mounted) {
      await context.read<CoupleRepository>().updateMilestones(
            coupleId: coupleId,
            weddingDate: d,
          );
    }
  }
}
