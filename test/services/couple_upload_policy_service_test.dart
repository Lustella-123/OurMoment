import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourmoment/core/constants.dart';
import 'package:ourmoment/services/couple_upload_policy_service.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this._user);
  final User? _user;

  @override
  User? get currentUser => _user;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  test('무료 사용자는 이번 달 photoCount 합으로 월 한도를 계산한다', () async {
    final db = FakeFirebaseFirestore();
    const coupleId = 'c1';
    const uid = 'u1';

    await db.collection('couples').doc(coupleId).set({
      'isPremium': false,
    });
    await db
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .doc('m1')
        .set({
          'dayKey': '2026-04-01',
          'photoCount': 58,
        });

    final service = CoupleUploadPolicyService(
      firestore: db,
      auth: _FakeAuth(_FakeUser(uid)),
    );

    final policy = await service.fetchPolicy(
      coupleId: coupleId,
      now: DateTime(2026, 4, 10),
    );

    expect(policy.isPremium, isFalse);
    expect(policy.monthlyUsedPhotos, 58);
    expect(policy.monthlyLimit, kFreeMonthlyPhotoLimit);
    expect(
      () => service.assertCanUpload(policy: policy, pendingPhotos: 3),
      throwsA(isA<MonthlyPhotoLimitExceededException>()),
    );
  });

  test('프리미엄 사용자는 한도 제한 없이 업로드 허용', () async {
    final db = FakeFirebaseFirestore();
    const coupleId = 'c2';
    const uid = 'u2';

    await db.collection('couples').doc(coupleId).set({
      'subscription': {'status': 'active'},
    });

    final service = CoupleUploadPolicyService(
      firestore: db,
      auth: _FakeAuth(_FakeUser(uid)),
    );
    final policy = await service.fetchPolicy(coupleId: coupleId);

    expect(policy.isPremium, isTrue);
    expect(policy.canUpload(999), isTrue);
    await service.assertCanUpload(policy: policy, pendingPhotos: 999);
  });
}
