import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'moments_repository.dart';

class _InviteCodeTaken implements Exception {}

class _InviteUserAlreadyHasCode implements Exception {}

/// Firestore `users/{uid}` — 커플 연결·프로필의 기준 문서.
///
/// - `inviteCode` (String, 6자): 계정에 **고정**되는 개인 초대 코드 (`inviteCodes/{code}`와 동기화)
/// - `coupleId`, `displayName`, …
class UserRepository {
  UserRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _db = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const inviteCodeLength = 6;

  DocumentReference<Map<String, dynamic>> ref(String uid) =>
      _db.collection('users').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      ref(uid).snapshots();

  String _randomInviteCode() {
    final r = Random.secure();
    return List.generate(
      inviteCodeLength,
      (_) => _chars[r.nextInt(_chars.length)],
    ).join();
  }

  /// 최초 1회 `inviteCode` + `inviteCodes/{code}` 를 트랜잭션으로 부여 (중복 방지).
  Future<void> ensurePersonalInviteCode(String uid) async {
    final userRef = ref(uid);
    final existing = await userRef.get();
    final cur = existing.data()?['inviteCode'] as String?;
    if (cur != null && cur.length == inviteCodeLength) return;

    for (var attempt = 0; attempt < 48; attempt++) {
      final code = _randomInviteCode();
      final codeRef = _db.collection('inviteCodes').doc(code);
      try {
        await _db.runTransaction((txn) async {
          final uSnap = await txn.get(userRef);
          final done = uSnap.data()?['inviteCode'] as String?;
          if (done != null && done.length == inviteCodeLength) {
            throw _InviteUserAlreadyHasCode();
          }
          final cSnap = await txn.get(codeRef);
          if (cSnap.exists) {
            throw _InviteCodeTaken();
          }
          txn.set(codeRef, {'uid': uid});
          txn.set(userRef, {'inviteCode': code}, SetOptions(merge: true));
        });
        return;
      } on _InviteUserAlreadyHasCode {
        return;
      } on _InviteCodeTaken {
        continue;
      } on FirebaseException catch (e) {
        // 권한 거부 등은 48번 재시도해도 소용없음
        debugPrint('inviteCodes transaction: ${e.code} ${e.message}');
        rethrow;
      }
    }
    throw StateError('invite_code_allocation_failed');
  }

  Future<void> ensureUserProfile(User user) async {
    final doc = ref(user.uid);
    await doc.set({
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first ?? '',
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await ensurePersonalInviteCode(user.uid);
    } catch (e, st) {
      // inviteCodes 규칙 미배포·권한 오류 시에도 앱은 진행 (연결 화면에서 재시도)
      debugPrint('ensurePersonalInviteCode failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<String?> getCoupleId(String uid) async {
    final snap = await ref(uid).get();
    return snap.data()?['coupleId'] as String?;
  }

  Future<void> updateDisplayName(String uid, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 40) trimmed = trimmed.substring(0, 40);
    await ref(uid).set({'displayName': trimmed}, SetOptions(merge: true));
  }

  /// Storage `users/{uid}/profile/avatar.jpg` → Firestore `photoUrl`
  Future<void> uploadProfilePhoto(String uid, Uint8List imageBytes) async {
    var compressed = await MomentsRepository.compressForUpload(
      imageBytes,
      tier: UploadTier.premium,
    );
    const maxProfileBytes = 4 * 1024 * 1024;
    if (compressed.length > maxProfileBytes) {
      for (final quality in [74, 66, 58, 50]) {
        final out = await FlutterImageCompress.compressWithList(
          compressed,
          minWidth: 1400,
          minHeight: 1400,
          quality: quality,
        );
        if (out.isEmpty) continue;
        compressed = Uint8List.fromList(out);
        if (compressed.length <= maxProfileBytes) break;
      }
    }
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref('users/$uid/profile/$fileName');
    await storageRef.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await storageRef.getDownloadURL();
    await ref(uid).set({'photoUrl': url}, SetOptions(merge: true));
  }
}
