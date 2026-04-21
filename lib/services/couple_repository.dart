import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_repository.dart';

enum CoupleInviteError {
  invalidCode,
  cannotInviteSelf,
  alreadyCoupled,
  partnerNotPending,
  relationshipStartRequired,
  notAuthenticated,
}

class CoupleRepository {
  CoupleRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  static const _inviteChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCouple(String coupleId) =>
      _db.collection('couples').doc(coupleId).snapshots();

  Future<String> createInviteCode({
    required DateTime relationshipStartDate,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw CoupleInviteError.notAuthenticated;
    final uid = me.uid;
    final todayOnly = DateTime(
      relationshipStartDate.year,
      relationshipStartDate.month,
      relationshipStartDate.day,
    );

    for (var i = 0; i < 30; i++) {
      final code = _randomInviteCode();
      final inviteRef = _db.collection('inviteCodes').doc(code);
      final userRef = _db.collection('users').doc(uid);
      try {
        await _db.runTransaction((txn) async {
          final userSnap = await txn.get(userRef);
          final status = (userSnap.data()?['status'] as String?) ?? 'SOLO';
          if (status == 'COUPLED') throw CoupleInviteError.alreadyCoupled;

          final inviteSnap = await txn.get(inviteRef);
          if (inviteSnap.exists) {
            throw StateError('collision');
          }

          txn.set(inviteRef, {
            'creatorUid': uid,
            'relationshipStartDate': Timestamp.fromDate(todayOnly),
            'createdAt': FieldValue.serverTimestamp(),
          });
          txn.set(userRef, {
            'status': 'PENDING',
            'inviteCode': code,
            'pendingPartnerUid': null,
            'relationshipStartDate': Timestamp.fromDate(todayOnly),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
        return code;
      } on StateError {
        continue;
      }
    }
    throw StateError('invite_code_generation_failed');
  }

  Future<void> cancelPendingInvite() async {
    final me = _auth.currentUser;
    if (me == null) throw CoupleInviteError.notAuthenticated;
    final userRef = _db.collection('users').doc(me.uid);
    final userSnap = await userRef.get();
    final inviteCode = userSnap.data()?['inviteCode'] as String?;
    if (inviteCode != null && inviteCode.isNotEmpty) {
      await _db.collection('inviteCodes').doc(inviteCode).delete();
    }
    await userRef.set({
      'status': 'SOLO',
      'inviteCode': null,
      'pendingPartnerUid': null,
      'relationshipStartDate': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptInvite(String rawCode) async {
    final me = _auth.currentUser;
    if (me == null) throw CoupleInviteError.notAuthenticated;
    final myUid = me.uid;
    final code = rawCode.trim().toUpperCase();
    if (code.length != UserRepository.inviteCodeLength) {
      throw CoupleInviteError.invalidCode;
    }

    final myRef = _db.collection('users').doc(myUid);
    final inviteRef = _db.collection('inviteCodes').doc(code);

    await _db.runTransaction((txn) async {
      final mySnap = await txn.get(myRef);
      final myStatus = (mySnap.data()?['status'] as String?) ?? 'SOLO';
      if (myStatus == 'COUPLED') throw CoupleInviteError.alreadyCoupled;

      final inviteSnap = await txn.get(inviteRef);
      if (!inviteSnap.exists) throw CoupleInviteError.invalidCode;

      final inviteData = inviteSnap.data()!;
      final partnerUid = inviteData['creatorUid'] as String;
      final relationshipStart =
          inviteData['relationshipStartDate'] as Timestamp?;
      if (relationshipStart == null) {
        throw CoupleInviteError.relationshipStartRequired;
      }
      if (partnerUid == myUid) throw CoupleInviteError.cannotInviteSelf;

      final partnerRef = _db.collection('users').doc(partnerUid);
      final partnerSnap = await txn.get(partnerRef);
      final partnerStatus = (partnerSnap.data()?['status'] as String?) ?? 'SOLO';
      final partnerInviteCode = partnerSnap.data()?['inviteCode'] as String?;
      if (partnerStatus != 'PENDING' || partnerInviteCode != code) {
        throw CoupleInviteError.partnerNotPending;
      }

      final coupleRef = _db.collection('couples').doc();
      txn.set(coupleRef, {
        'memberIds': [partnerUid, myUid],
        'relationshipStartDate': relationshipStart,
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.set(partnerRef, {
        'status': 'COUPLED',
        'coupleId': coupleRef.id,
        'pendingPartnerUid': myUid,
        'inviteCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.set(myRef, {
        'status': 'COUPLED',
        'coupleId': coupleRef.id,
        'pendingPartnerUid': partnerUid,
        'inviteCode': null,
        'relationshipStartDate': relationshipStart,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.delete(inviteRef);
    });
  }

  String _randomInviteCode() {
    final random = Random.secure();
    return List.generate(
      UserRepository.inviteCodeLength,
      (_) => _inviteChars[random.nextInt(_inviteChars.length)],
    ).join();
  }
}
