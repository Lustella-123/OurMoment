import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/developer_allowlist.dart';
import '../../core/monetization.dart';
import '../../services/auth_repository.dart';
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../settings/couple_settings_section.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          if (user != null)
            Material(
              color:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: InkWell(
                onTap: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: StreamBuilder(
                    stream:
                        context.read<UserRepository>().watchUser(user.uid),
                    builder: (context, snap) {
                      final d = snap.data?.data();
                      final name = d?['displayName'] as String? ?? '';
                      final photo = d?['photoUrl'] as String?;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: scheme.surfaceContainerHigh,
                            backgroundImage: photo != null && photo.isNotEmpty
                                ? CachedNetworkImageProvider(photo)
                                : null,
                            child: photo == null || photo.isEmpty
                                ? Icon(Icons.person_rounded,
                                    color: scheme.outline, size: 32)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty
                                      ? l10n.profileTitle
                                      : name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.profileEntrySubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: scheme.outline),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(
              settings.languageCode == 'ko'
                  ? l10n.settingsLanguageKo
                  : l10n.settingsLanguageEn,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ko',
                  label: Text(l10n.settingsLanguageKo),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text(l10n.settingsLanguageEn),
                ),
              ],
              selected: {settings.languageCode},
              onSelectionChanged: (s) {
                final v = s.first;
                unawaited(context.read<AppSettings>().setLanguageCode(v));
              },
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.settingsAppearance,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '4가지 색 조합을 고르세요',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          _ThemePresetRow(
            presets: AppTheme.palettes,
            selectedThemeId: settings.themePalette.id,
            onPick: (preset) async {
              await context.read<AppSettings>().setThemeById(preset.id);
            },
          ),
          const Divider(height: 32),
          const CoupleSettingsSection(),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SubscriptionPromoCard(
              l10n: l10n,
              settings: settings,
              accent: settings.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: GestureDetector(
              onTap: () => _onVersionTap(context, settings),
              child: Text(
                '${l10n.settingsVersion} $kAppVersion',
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsLogout),
            onTap: () async {
              await context.read<AuthRepository>().signOut();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onVersionTap(BuildContext context, AppSettings settings) async {
    setState(() => _versionTapCount++);
    if (_versionTapCount < 5) return;
    _versionTapCount = 0;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DeveloperDialog(settings: settings),
    );
  }
}

class _SubscriptionPromoCard extends StatelessWidget {
  const _SubscriptionPromoCard({
    required this.l10n,
    required this.settings,
    required this.accent,
  });

  final AppLocalizations l10n;
  final AppSettings settings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.45),
            accent.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: accent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.subscriptionCardTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.subscriptionCardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 14),
              if (settings.isPremium)
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.premiumActive,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.subscriptionComingSoon)),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: accent,
                      foregroundColor: _contrastOn(accent),
                    ),
                    child: Text(
                      l10n.subscriptionCtaMonthly(kSubscriptionMonthlyKrw),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.subscriptionComingSoon)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.65)),
                    ),
                    child: Text(
                      l10n.subscriptionCtaYearly(kSubscriptionYearlyKrw),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _contrastOn(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.55 ? Colors.black87 : Colors.white;
  }
}

class _ThemePresetRow extends StatelessWidget {
  const _ThemePresetRow({
    required this.presets,
    required this.selectedThemeId,
    required this.onPick,
  });

  final List<AppThemePalette> presets;
  final String selectedThemeId;
  final ValueChanged<AppThemePalette> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = presets[i];
          final on = p.id == selectedThemeId;
          return GestureDetector(
            onTap: () => onPick(p),
            child: Container(
              width: 86,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: Border.all(
                  color: on ? Theme.of(context).colorScheme.primary : Colors.black12,
                  width: on ? 2.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _colorDot(p.c1),
                      const SizedBox(width: 6),
                      _colorDot(p.c2),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _colorDot(p.c3),
                      const SizedBox(width: 6),
                      _colorDot(p.c4),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: on ? 24 : 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: on ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorDot(Color c) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.4),
      ),
    );
  }
}

class _DeveloperDialog extends StatefulWidget {
  const _DeveloperDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_DeveloperDialog> createState() => _DeveloperDialogState();
}

class _DeveloperDialogState extends State<_DeveloperDialog> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Developer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            final email = _email.text.trim();
            final l10n = AppLocalizations.of(context)!;
            if (!isDeveloperPremiumEmail(email)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.developerPremiumDenied)),
              );
              return;
            }
            await widget.settings.setPremiumLocalStub(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.developerPremiumGranted)),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Premium (local)'),
        ),
      ],
    );
  }
}
