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
  inviteAlreadyClaimed,
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

    DocumentSnapshot<Map<String, dynamic>> codeSnap;
    try {
      codeSnap = await _db.collection('inviteCodes').doc(code).get();
    } catch (e) {
      _failAtStep(e, PairingStep.readInviteCodeDoc);
    }
    if (!codeSnap.exists) throw CoupleInviteError.invalidCode;

    final creatorUid = codeSnap.data()!['uid'] as String;
    if (creatorUid == uid) throw CoupleInviteError.cannotInviteSelf;

    final joinerRef = _db.collection('users').doc(uid);
    final inviteRef = _db.collection('inviteCodes').doc(code);

    String? newCoupleIdForJoiner;

    try {
      await _db.runTransaction((txn) async {
        final joinerSnap = await txn.get(joinerRef);
        if ((joinerSnap.data()?['coupleId'] as String?) != null) {
          throw CoupleInviteError.inviteeAlreadyPaired;
        }

        final inviteSnap = await txn.get(inviteRef);
        if (!inviteSnap.exists) throw CoupleInviteError.invalidCode;
        final inviteUid = inviteSnap.data()?['uid'] as String?;
        if (inviteUid == null || inviteUid != creatorUid) {
          throw CoupleInviteError.invalidCode;
        }
        final claimedBy = inviteSnap.data()?['claimedBy'] as String?;
        if (claimedBy != null && claimedBy != uid) {
          throw CoupleInviteError.inviteAlreadyClaimed;
        }
        if (claimedBy == null) {
          txn.update(inviteRef, {
            'claimedBy': uid,
            'claimedAt': FieldValue.serverTimestamp(),
          });
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
          txn.set(coupleRef, {
            'memberIds': [creatorUid, uid],
            'createdAt': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
            'loveTemperature': 0,
            'inviteCodeUsed': code,
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
        if (!members.contains(creatorUid)) throw CoupleInviteError.invalidCode;
        if (members.contains(uid)) {
          newCoupleIdForJoiner = creatorCoupleId;
          return;
        }
        throw CoupleInviteError.coupleFull;
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
