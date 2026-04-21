import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/user_repository.dart';
import '../../services/couple_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthRepository>().currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder(
      stream: context.read<UserRepository>().watchUser(uid),
      builder: (context, meSnap) {
        if (!meSnap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        final me = meSnap.data?.data() ?? const <String, dynamic>{};
        final coupleId = me['coupleId'] as String?;
        final myName = (me['displayName'] as String?) ?? '나';
        if (coupleId == null || coupleId.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                '커플 연결 정보를 찾을 수 없습니다.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        }
        return StreamBuilder(
          stream: context.read<CoupleRepository>().watchCouple(coupleId),
          builder: (context, coupleSnap) {
            if (!coupleSnap.hasData) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            }
            final couple = coupleSnap.data?.data() ?? const <String, dynamic>{};
            final members = List<String>.from(
              couple['memberIds'] as List<dynamic>? ?? const [],
            );
            final partnerUid = members.firstWhere(
              (id) => id != uid,
              orElse: () => '',
            );
            if (partnerUid.isEmpty) {
              return _SimpleHome(
                myName: myName,
                partnerName: '상대',
                relationshipStartText: '사귄 날짜 없음',
              );
            }
            return StreamBuilder(
              stream: context.read<UserRepository>().watchUser(partnerUid),
              builder: (context, partnerSnap) {
                final partnerName =
                    (partnerSnap.data?.data()?['displayName'] as String?) ?? '상대';
                final relationshipStart =
                    couple['relationshipStartDate'] as dynamic;
                String relationshipStartText = '사귄 날짜 없음';
                if (relationshipStart != null) {
                  final date = relationshipStart.toDate() as DateTime;
                  relationshipStartText =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
                return _SimpleHome(
                  myName: myName,
                  partnerName: partnerName,
                  relationshipStartText: relationshipStartText,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SimpleHome extends StatelessWidget {
  const _SimpleHome({
    required this.myName,
    required this.partnerName,
    required this.relationshipStartText,
  });

  final String myName;
  final String partnerName;
  final String relationshipStartText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Our Moment 홈'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '연결 완료',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '나: $myName',
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '상대: $partnerName',
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '사귄 날짜: $relationshipStartText',
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.read<AuthRepository>().signOut(),
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
