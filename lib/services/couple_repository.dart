import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_repository.dart';

/// 연결 실패 시 **어느 단계**에서 막혔는지 표시용 (UI·로그)
enum PairingStep {
  readInviteCodeDoc('① inviteCodes/{코드} 읽기'),
  readCreatorUser('② 상대 users/{uid} 읽기'),
  repairReadCouple('③ 복구: couples/{id} 읽기'),
  repairReadJoiner('④ 복구: 내 users 읽기'),
  repairUpdateJoiner('⑤ 복구: 내 users에 coupleId 쓰기'),
  transaction('⑥ 트랜잭션 (커플 문서·상대 users 갱신)'),
  joinerSetCoupleId('⑦ 트랜잭션 후: 내 users에 coupleId 쓰기');

  const PairingStep(this.labelKo);
  final String labelKo;
}

/// [step]에서 실패했을 때 [cause]를 감쌉니다.
class PairingStepException implements Exception {
  PairingStepException(this.step, this.cause);

  final PairingStep step;
  final Object cause;

  @override
  String toString() => '${step.labelKo}\n$cause';
}

enum CoupleInviteError {
  invalidCode,
  cannotInviteSelf,
  alreadyInCouple,
  coupleFull,
  inviteeAlreadyPaired,
  notAuthenticated,
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

  Future<DocumentSnapshot<Map<String, dynamic>>> getCouple(String coupleId) =>
      coupleRef(coupleId).get();

  /// catch 블록에서만 호출. `rethrow`는 헬퍼 안에서 쓸 수 없어 `throw e`로 전달합니다.
  Never _failAtStep(Object e, PairingStep step) {
    if (e is CoupleInviteError) throw e;
    if (e is PairingStepException) throw e;
    throw PairingStepException(step, e);
  }

  /// 상대의 **고정 inviteCode**로 연결. `inviteCodes/{code}` → 작성자 uid 조회.
  Future<void> acceptInvite(String rawCode) async {
    final user = _auth.currentUser;
    if (user == null) throw CoupleInviteError.notAuthenticated;

    final uid = user.uid;
    final code = rawCode.trim().toUpperCase();
    if (code.length != UserRepository.inviteCodeLength) {
      throw CoupleInviteError.invalidCode;
    }

    String? creatorUid;
    try {
      final codeSnap = await _db.collection('inviteCodes').doc(code).get();
      if (codeSnap.exists) {
        creatorUid = codeSnap.data()?['uid'] as String?;
      }
    } on FirebaseException catch (e) {
      // inviteCodes 규칙 미배포/권한 거부 시 users 기반 폴백으로 진행
      if (e.code != 'permission-denied' && e.code != 'failed-precondition') {
        _failAtStep(e, PairingStep.readInviteCodeDoc);
      }
    } catch (e) {
      _failAtStep(e, PairingStep.readInviteCodeDoc);
    }
    creatorUid ??= await _findCreatorUidByCodeInUsers(code);
    if (creatorUid == null || creatorUid.isEmpty) {
      throw CoupleInviteError.invalidCode;
    }
    if (creatorUid == uid) throw CoupleInviteError.cannotInviteSelf;

    DocumentSnapshot<Map<String, dynamic>> creatorUserSnap;
    try {
      creatorUserSnap = await _db.collection('users').doc(creatorUid).get();
    } catch (e) {
      _failAtStep(e, PairingStep.readCreatorUser);
    }
    final onUser = creatorUserSnap.data()?['inviteCode'] as String?;
    if (onUser == null || onUser.toUpperCase() != code) {
      throw CoupleInviteError.invalidCode;
    }

    final joinerRef = _db.collection('users').doc(uid);

    // 이전 시도에서 couples만 반영되고 users.coupleId 쓰기가 실패한 경우 — 재시도 시 coupleFull에 걸리지 않게 복구
    final existingCreatorCoupleId =
        creatorUserSnap.data()?['coupleId'] as String?;
    if (existingCreatorCoupleId != null) {
      DocumentSnapshot<Map<String, dynamic>> preCouple;
      try {
        preCouple =
            await _db.collection('couples').doc(existingCreatorCoupleId).get();
      } catch (e) {
        _failAtStep(e, PairingStep.repairReadCouple);
      }
      if (preCouple.exists) {
        final preMembers = List<String>.from(
          preCouple.data()?['memberIds'] as List<dynamic>? ?? [],
        );
        if (preMembers.contains(uid) && preMembers.contains(creatorUid)) {
          DocumentSnapshot<Map<String, dynamic>> mePre;
          try {
            mePre = await joinerRef.get();
          } catch (e) {
            _failAtStep(e, PairingStep.repairReadJoiner);
          }
          final myCid = mePre.data()?['coupleId'] as String?;
          if (myCid == null) {
            try {
              await joinerRef.update({'coupleId': existingCreatorCoupleId});
            } catch (e) {
              _failAtStep(e, PairingStep.repairUpdateJoiner);
            }
            return;
          }
          if (myCid == existingCreatorCoupleId) {
            return;
          }
        }
      }
    }

    String? newCoupleIdForJoiner;

    try {
      await _db.runTransaction((txn) async {
        final joinerSnap = await txn.get(joinerRef);
        if ((joinerSnap.data()?['coupleId'] as String?) != null) {
          throw CoupleInviteError.inviteeAlreadyPaired;
        }

        final creatorRef = _db.collection('users').doc(creatorUid);
        final creatorSnap = await txn.get(creatorRef);
        if (!creatorSnap.exists) throw CoupleInviteError.invalidCode;

        final inv = creatorSnap.data()?['inviteCode'] as String?;
        if (inv == null || inv.toUpperCase() != code) {
          throw CoupleInviteError.invalidCode;
        }

        final creatorCoupleId = creatorSnap.data()?['coupleId'] as String?;

        if (creatorCoupleId == null) {
          final coupleRef = _db.collection('couples').doc();
          final newId = coupleRef.id;
          // serverTimestamp는 규칙 keys()와 맞지 않아 거절되는 사례 있음 — 클라이언트 Timestamp로 통일
          txn.set(coupleRef, {
            'memberIds': [creatorUid, uid],
            'createdAt': Timestamp.now(),
            'loveTemperature': 0,
          });
          txn.update(creatorRef, {'coupleId': newId});
          newCoupleIdForJoiner = newId;
          return;
        }

        final coupleRef = _db.collection('couples').doc(creatorCoupleId);
        final coupleSnap = await txn.get(coupleRef);
        if (!coupleSnap.exists) throw CoupleInviteError.invalidCode;

        final members = List<String>.from(
          coupleSnap.data()!['memberIds'] as List<dynamic>,
        );
        if (members.length >= 2) throw CoupleInviteError.coupleFull;
        if (!members.contains(creatorUid)) throw CoupleInviteError.invalidCode;
        if (members.contains(uid)) throw CoupleInviteError.alreadyInCouple;

        members.add(uid);
        txn.update(coupleRef, {'memberIds': members});
        newCoupleIdForJoiner = creatorCoupleId;
      });
    } catch (e) {
      if (e is CoupleInviteError) rethrow;
      _failAtStep(e, PairingStep.transaction);
    }

    final cid = newCoupleIdForJoiner;
    if (cid != null) {
      try {
        await joinerRef.update({'coupleId': cid});
      } catch (e) {
        _failAtStep(e, PairingStep.joinerSetCoupleId);
      }
    }
  }

  Future<String?> _findCreatorUidByCodeInUsers(String code) async {
    final q = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  /// 연애 시작일·결혼 기념일 (커플 멤버만)
  Future<void> updateMilestones({
    required String coupleId,
    DateTime? relationshipStart,
    DateTime? weddingDate,
    bool clearRelationshipStart = false,
    bool clearWeddingDate = false,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
        DateTime(
          weddingDate.year,
          weddingDate.month,
          weddingDate.day,
        ),
      );
    }
    if (data.length == 1) return;
    await coupleRef(coupleId).update(data);
  }

  /// 연결 직후 기념일 안내를 마쳤음 (다시 띄우지 않음)
  Future<void> markMilestonesOnboardingDone(String coupleId) async {
    await coupleRef(coupleId).set(
      {
        'milestonesOnboardingDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
