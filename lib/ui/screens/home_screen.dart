import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/user_repository.dart';
import 'diary_screen.dart';

/// MVP 홈: 오늘의 기록 진입만 제공합니다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.homeTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : StreamBuilder(
              stream: context.read<UserRepository>().watchUser(user.uid),
              builder: (context, userSnap) {
                final coupleId = userSnap.data?.data()?['coupleId'] as String?;
                if (coupleId == null || coupleId.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.feedConnectFirst,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton(
                      onPressed: () {
                        unawaited(
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const DiaryScreen(),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        l10n.homeRecordButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
