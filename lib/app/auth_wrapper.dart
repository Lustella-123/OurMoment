import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_repository.dart';
import '../services/user_repository.dart';
import '../ui/auth/login_screen.dart';
import '../ui/pairing/pairing_screen.dart';
import '../ui/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    return StreamBuilder<User?>(
      stream: authRepo.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _SimpleCenterText(text: '로딩 중...');
        }
        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }
        return _UserStatusGate(user: user);
      },
    );
  }
}

class _UserStatusGate extends StatelessWidget {
  const _UserStatusGate({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();
    return FutureBuilder<void>(
      future: userRepo.ensureUserProfile(user),
      builder: (context, initSnap) {
        if (initSnap.connectionState != ConnectionState.done) {
          return const _SimpleCenterText(text: '프로필 준비 중...');
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userRepo.watchUser(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting &&
                !userSnap.hasData) {
              return const _SimpleCenterText(text: '상태 동기화 중...');
            }
            final status =
                (userSnap.data?.data()?['status'] as String?) ?? 'SOLO';
            if (status == 'SOLO') {
              return const PairingScreen();
            }
            if (status == 'PENDING') {
              return const PendingScreen();
            }
            if (status == 'COUPLED') {
              return const HomeScreen();
            }
            return const _SimpleCenterText(text: '알 수 없는 상태');
          },
        );
      },
    );
  }
}

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const LoginScreen();
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().watchUser(currentUser.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _SimpleCenterText(text: '초대 상태 확인 중...');
        }
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final inviteCode = (data['inviteCode'] as String?) ?? '-';
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '대기 중',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '상대가 초대 코드를 입력하면 자동으로 홈 화면으로 이동합니다.',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '내 초대 코드: $inviteCode',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthRepository>().signOut();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SimpleCenterText extends StatelessWidget {
  const _SimpleCenterText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
    );
  }
}
