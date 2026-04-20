import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/auth_repository.dart';
import '../services/invite_deep_link.dart';
import '../services/user_repository.dart';
import '../state/app_settings.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/verify_email_screen.dart';
import '../ui/pairing/pairing_screen.dart';
import '../ui/splash/our_moment_splash_layout.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AppLinks _appLinks;
  // dispose에서 cancel — cancel_subscriptions는 StatefulWidget 필드 패턴을 추적하지 못함.
  // ignore: cancel_subscriptions
  StreamSubscription<Uri>? _linkSub;
  String? _pendingInviteCode;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    unawaited(_listenDeepLinks());
  }

  Future<void> _listenDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      final c = parseInviteCodeFromUri(initial);
      if (c != null && mounted) setState(() => _pendingInviteCode = c);
    } catch (e) {
      debugPrint('getInitialLink failed: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      final c = parseInviteCodeFromUri(uri);
      if (c != null && mounted) setState(() => _pendingInviteCode = c);
    });
  }

  @override
  void dispose() {
    final sub = _linkSub;
    if (sub != null) unawaited(sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: authRepo.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _SplashScaffold();
        }

        final user = snap.data ?? FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        if (authRepo.needsEmailVerification(user)) {
          return VerifyEmailScreen(user: user);
        }

        return _ProfileBootstrap(
          user: user,
          pendingInviteCode: _pendingInviteCode,
        );
      },
    );
  }
}

class _ProfileBootstrap extends StatefulWidget {
  const _ProfileBootstrap({required this.user, this.pendingInviteCode});

  final User user;
  final String? pendingInviteCode;

  @override
  State<_ProfileBootstrap> createState() => _ProfileBootstrapState();
}

class _ProfileBootstrapState extends State<_ProfileBootstrap> {
  late Future<void> _future;
  bool _profileLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoadStarted) return;
    _profileLoadStarted = true;
    _future = context.read<UserRepository>().ensureUserProfile(widget.user);
  }

  void _retry() {
    setState(() {
      _future = context.read<UserRepository>().ensureUserProfile(widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashScaffold();
        }
        if (snap.hasError) {
          return _BootstrapErrorScreen(
            title: l10n.errorProfileLoadTitle,
            message: _friendlyError(context, snap.error),
            onRetry: _retry,
          );
        }
        return _CoupleGate(
          uid: widget.user.uid,
          pendingInviteCode: widget.pendingInviteCode,
        );
      },
    );
  }
}

String _friendlyError(BuildContext context, Object? error) {
  if (error == null) return '알 수 없는 오류';
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore 규칙을 확인해 주세요. (permission-denied)';
      case 'unavailable':
        return '네트워크를 확인한 뒤 다시 시도해 주세요.';
      default:
        return error.message ?? error.code;
    }
  }
  return error.toString();
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoupleGate extends StatefulWidget {
  const _CoupleGate({required this.uid, this.pendingInviteCode});

  final String uid;
  final String? pendingInviteCode;

  @override
  State<_CoupleGate> createState() => _CoupleGateState();
}

class _CoupleGateState extends State<_CoupleGate> {
  int _streamRetry = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey(_streamRetry),
      stream: context.read<UserRepository>().watchUser(widget.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _BootstrapErrorScreen(
            title: l10n.errorFirestoreTitle,
            message: _friendlyError(context, snap.error ?? 'unknown'),
            onRetry: () => setState(() => _streamRetry++),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _SplashScaffold();
        }
        if (!snap.hasData) {
          return const _SplashScaffold();
        }
        final data = snap.data?.data();
        final coupleId = data?['coupleId'] as String?;
        final status = _normalizedStatus(data);
        if (status == UserRepository.statusSolo) {
          return PairingScreen(
            uid: widget.uid,
            mode: PairingScreenMode.solo,
            initialInviteCode: widget.pendingInviteCode,
          );
        }
        if (status == UserRepository.statusPending) {
          return PairingScreen(
            uid: widget.uid,
            mode: PairingScreenMode.pending,
          );
        }
        if (status == UserRepository.statusCoupled &&
            coupleId != null &&
            coupleId.isNotEmpty) {
          return CoupledHomeScreen(uid: widget.uid, coupleId: coupleId);
        }
        return PairingScreen(
          uid: widget.uid,
          mode: PairingScreenMode.solo,
          initialInviteCode: widget.pendingInviteCode,
        );
      },
    );
  }

  String _normalizedStatus(Map<String, dynamic>? data) {
    final raw = (data?['status'] as String?)?.toUpperCase();
    if (raw == UserRepository.statusSolo ||
        raw == UserRepository.statusPending ||
        raw == UserRepository.statusCoupled) {
      return raw!;
    }
    return UserRepository.statusSolo;
  }
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return Scaffold(
      body: OurMomentSplashLayout(palette: settings.themePalette),
    );
  }
}
