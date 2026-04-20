import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'moments_repository.dart';

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

  static const inviteCodeLength = 6;
  static const statusSolo = 'SOLO';
  static const statusPending = 'PENDING';
  static const statusCoupled = 'COUPLED';

  DocumentReference<Map<String, dynamic>> ref(String uid) =>
      _db.collection('users').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      ref(uid).snapshots();

  /// 초대 코드는 사귄 날짜 선택과 함께 CoupleRepository에서 생성한다.
  @Deprecated('Use CoupleRepository.createInviteCode with relationshipStart.')
  Future<void> ensurePersonalInviteCode(String uid) async {
    throw StateError('relationship_start_required');
  }

  Future<void> ensureUserProfile(User user) async {
    final doc = ref(user.uid);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(doc);
      final data = snap.data() ?? <String, dynamic>{};
      final nextStatus = _inferOrDefaultStatus(data);
      txn.set(doc, {
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@').first ?? '',
        'photoUrl': user.photoURL,
        'status': nextStatus,
        if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _inferOrDefaultStatus(Map<String, dynamic> data) {
    final raw = (data['status'] as String?)?.toUpperCase();
    if (raw == statusSolo || raw == statusPending || raw == statusCoupled) {
      return raw!;
    }
    final coupleId = data['coupleId'] as String?;
    if (coupleId != null && coupleId.isNotEmpty) {
      return statusCoupled;
    }
    return statusSolo;
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
    final compressed = await MomentsRepository.compressForUpload(imageBytes);
    final storageRef = _storage.ref('users/$uid/profile/avatar.jpg');
    await storageRef.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await storageRef.getDownloadURL();
    await ref(uid).set({'photoUrl': url}, SetOptions(merge: true));
  }
}
