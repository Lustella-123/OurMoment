import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_repository.dart';
import '../../services/couple_repository.dart';
import '../../services/invite_deep_link.dart';
import '../../services/user_repository.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, this.initialInviteCode});

  final String? initialInviteCode;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeCtrl = TextEditingController();
  /// 연결하기 진행 중 — 공유 버튼은 막지 않음
  bool _busyConnect = false;
  bool _busyEnsureCode = false;
  bool _busyLogout = false;
  /// 마지막 실패 시 단계·상세 (옆/아래 패널)
  String? _pairingDiagnostic;

  @override
  void initState() {
    super.initState();
    final i = widget.initialInviteCode;
    if (i != null && i.isNotEmpty) {
      _codeCtrl.text = i.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _mapError(AppLocalizations l10n, CoupleInviteError e) {
    switch (e) {
      case CoupleInviteError.invalidCode:
        return l10n.inviteErrorInvalid;
      case CoupleInviteError.inviteAlreadyClaimed:
        return l10n.inviteErrorAlreadyClaimed;
      case CoupleInviteError.cannotInviteSelf:
        return l10n.inviteErrorSelf;
      case CoupleInviteError.alreadyInCouple:
      case CoupleInviteError.inviteeAlreadyPaired:
        return l10n.inviteErrorAlreadyPaired;
      case CoupleInviteError.coupleFull:
        return l10n.inviteErrorFull;
      case CoupleInviteError.notAuthenticated:
        return l10n.inviteErrorGeneric;
    }
  }

  Future<void> _ensureCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busyEnsureCode = true);
    try {
      await context.read<UserRepository>().ensurePersonalInviteCode(uid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busyEnsureCode = false);
    }
  }

  Future<void> _accept() async {
    setState(() {
      _busyConnect = true;
      _pairingDiagnostic = null;
    });
    try {
      await context.read<CoupleRepository>().acceptInvite(_codeCtrl.text);
      if (mounted) setState(() => _pairingDiagnostic = null);
    } on CoupleInviteError catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final msg = _mapError(l10n, e);
      setState(() => _pairingDiagnostic = '앱 검증 단계\n$msg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } on PairingStepException catch (e) {
      if (!mounted) return;
      setState(() => _pairingDiagnostic = e.step.labelKo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${e.step.labelKo}\n다시 시도해 주세요.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final detail = '기타 오류';
      setState(() => _pairingDiagnostic = detail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inviteErrorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _busyConnect = false);
    }
  }

  Future<void> _share(String code) async {
    final l10n = AppLocalizations.of(context)!;
    final link = inviteDeepLink(code);
    final text = l10n.inviteShareText(code, link);
    await Share.share(text);
  }

  Future<void> _logout() async {
    if (_busyConnect || _busyEnsureCode || _busyLogout) return;
    setState(() => _busyLogout = true);
    try {
      await context.read<AuthRepository>().signOut();
    } finally {
      if (mounted) setState(() => _busyLogout = false);
    }
  }

  bool get _anyBusy =>
      _busyConnect || _busyEnsureCode || _busyLogout;

  List<Widget> _formChildren(AppLocalizations l10n, String? uid) {
    return [
          Text(l10n.pairingBody, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            l10n.pairingCodeFixedHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (uid == null)
            const SizedBox.shrink()
          else
            StreamBuilder(
              stream: context.read<UserRepository>().watchUser(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${snap.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final code = snap.data?.data()?['inviteCode'] as String?;
                if (code == null || code.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.qr_code_2_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.pairingInviteCodeMissingBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busyEnsureCode ? null : _ensureCode,
                        child: Text(l10n.pairingCodeLoadRetry),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.pairingYourCode,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      code,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _share(code),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.pairingShare),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 36),
          Text(
            l10n.pairingCodeHint,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l10n.pairingCodeHint,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busyConnect ? null : _accept,
            child: _busyConnect
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.pairingConnect),
          ),
          const SizedBox(height: 28),
          Center(
            child: TextButton(
              onPressed: _anyBusy ? null : _logout,
              child: Text(l10n.settingsLogout),
            ),
          ),
          if (_pairingDiagnostic != null &&
              MediaQuery.sizeOf(context).width < 520) ...[
            const SizedBox(height: 20),
            _diagnosticCard(context),
          ],
    ];
  }

  Widget _diagnosticCard(BuildContext context) {
    final t = _pairingDiagnostic;
    if (t == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '연결 시도 진단',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              t,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final showSidePanel =
        MediaQuery.sizeOf(context).width >= 520 && _pairingDiagnostic != null;
    final formChildren = _formChildren(l10n, uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairingTitle),
      ),
      body: showSidePanel
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: formChildren,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  flex: 9,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [_diagnosticCard(context)],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: formChildren,
            ),
    );
  }
}
