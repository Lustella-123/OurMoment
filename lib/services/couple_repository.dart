import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'user_repository.dart';

class _InviteCodeTaken implements Exception {}

enum CoupleInviteError {
  invalidCode,
  cannotInviteSelf,
  alreadyInCouple,
  coupleFull,
  inviteeAlreadyPaired,
  notAuthenticated,
  relationshipStartRequired,
}

class CoupleRepository {
  CoupleRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> coupleRef(String coupleId) =>
      _db.collection('couples').doc(coupleId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCouple(String coupleId) =>
      coupleRef(coupleId).snapshots();

  static const _chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  String _randomInviteCode() {
    final r = Random.secure();
    return List.generate(
      UserRepository.inviteCodeLength,
      (_) => _chars[r.nextInt(_chars.length)],
    ).join();
  }

  /// SOLO 유저가 반드시 사귄 날짜를 먼저 선택한 뒤 초대 코드를 생성.
  Future<String> createInviteCode({required DateTime relationshipStart}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw CoupleInviteError.notAuthenticated;
    }
    final start = DateTime(
      relationshipStart.year,
      relationshipStart.month,
      relationshipStart.day,
    );
    if (start.isAfter(DateTime.now())) {
      throw CoupleInviteError.relationshipStartRequired;
    }

    final uid = user.uid;
    final userRef = _db.collection('users').doc(uid);
    for (var attempt = 0; attempt < 48; attempt++) {
      try {
        final code = await _db.runTransaction<String>((txn) async {
          final me = await txn.get(userRef);
          final meData = me.data() ?? <String, dynamic>{};
          final myCoupleId = meData['coupleId'] as String?;
          final myStatus = (meData['status'] as String?)?.toUpperCase();
          if (myCoupleId != null || myStatus == UserRepository.statusCoupled) {
            throw CoupleInviteError.alreadyInCouple;
          }

          final existingCode = meData['inviteCode'] as String?;
          final code =
              (existingCode != null &&
                  existingCode.length == UserRepository.inviteCodeLength)
              ? existingCode
              : _randomInviteCode();
          if (existingCode == null || existingCode.isEmpty) {
            final codeRef = _db.collection('inviteCodes').doc(code);
            final codeSnap = await txn.get(codeRef);
            if (codeSnap.exists) {
              throw _InviteCodeTaken();
            }
            txn.set(codeRef, {'uid': uid});
          }

          txn.set(userRef, {
            'inviteCode': code,
            'relationshipStart': Timestamp.fromDate(start),
            'status': UserRepository.statusPending,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return code;
        });
        return code;
      } on _InviteCodeTaken {
        continue;
      }
    }
    throw StateError('invite_code_allocation_failed');
  }

  /// 초대 코드를 입력한 사용자를 커플에 연결하고, 양측 status를 COUPLED로 전환.
  Future<void> acceptInvite(String rawCode) async {
    final user = _auth.currentUser;
    if (user == null) throw CoupleInviteError.notAuthenticated;

    final uid = user.uid;
    final code = rawCode.trim().toUpperCase();
    if (code.length != UserRepository.inviteCodeLength) {
      throw CoupleInviteError.invalidCode;
    }

    final codeSnap = await _db.collection('inviteCodes').doc(code).get();
    if (!codeSnap.exists) throw CoupleInviteError.invalidCode;

    final creatorUid = codeSnap.data()!['uid'] as String;
    if (creatorUid == uid) throw CoupleInviteError.cannotInviteSelf;

    final joinerRef = _db.collection('users').doc(uid);
    final creatorRef = _db.collection('users').doc(creatorUid);

    String? newCoupleIdForJoiner;
    await _db.runTransaction((txn) async {
      final joinerSnap = await txn.get(joinerRef);
      final joinerCoupleId = joinerSnap.data()?['coupleId'] as String?;
      if (joinerCoupleId != null) {
        throw CoupleInviteError.inviteeAlreadyPaired;
      }

      final creatorSnap = await txn.get(creatorRef);
      final creatorData = creatorSnap.data();
      if (creatorData == null) {
        throw CoupleInviteError.invalidCode;
      }
      final creatorCoupleId = creatorData['coupleId'] as String?;
      if (creatorCoupleId != null) {
        throw CoupleInviteError.coupleFull;
      }
      final creatorCode = (creatorData['inviteCode'] as String?)?.toUpperCase();
      if (creatorCode != code) {
        throw CoupleInviteError.invalidCode;
      }

      final relationshipStart = creatorData['relationshipStart'];
      final normalizedRelationshipStart = relationshipStart is Timestamp
          ? Timestamp.fromDate(
              DateTime(
                relationshipStart.toDate().year,
                relationshipStart.toDate().month,
                relationshipStart.toDate().day,
              ),
            )
          : Timestamp.now();

      final coupleRef = _db.collection('couples').doc();
      final coupleId = coupleRef.id;
      txn.set(coupleRef, {
        'memberIds': [creatorUid, uid],
        'relationshipStart': normalizedRelationshipStart,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      txn.update(creatorRef, {
        'coupleId': coupleId,
        'status': UserRepository.statusCoupled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      newCoupleIdForJoiner = coupleId;
    });

    final cid = newCoupleIdForJoiner;
    if (cid == null) return;
    await joinerRef.update({
      'coupleId': cid,
      'status': UserRepository.statusCoupled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 연애 시작일·결혼 기념일 (커플 멤버만)
  Future<void> updateMilestones({
    required String coupleId,
    DateTime? relationshipStart,
    DateTime? weddingDate,
    bool clearRelationshipStart = false,
    bool clearWeddingDate = false,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (clearRelationshipStart) {
      data['relationshipStart'] = FieldValue.delete();
    } else if (relationshipStart != null) {
      data['relationshipStart'] = Timestamp.fromDate(
        DateTime(
          relationshipStart.year,
          relationshipStart.month,
          relationshipStart.day,
        ),
      );
    }
    if (clearWeddingDate) {
      data['weddingDate'] = FieldValue.delete();
    } else if (weddingDate != null) {
      data['weddingDate'] = Timestamp.fromDate(
        DateTime(weddingDate.year, weddingDate.month, weddingDate.day),
      );
    }
    if (data.length == 1) return;
    await coupleRef(coupleId).update(data);
  }

  /// 연결 직후 기념일 안내를 마쳤음 (다시 띄우지 않음)
  Future<void> markMilestonesOnboardingDone(String coupleId) async {
    await coupleRef(coupleId).set({
      'milestonesOnboardingDone': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
