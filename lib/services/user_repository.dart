import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const inviteCodeLength = 6;

  DocumentReference<Map<String, dynamic>> ref(String uid) =>
      _db.collection('users').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      ref(uid).snapshots();

  Future<void> ensureUserProfile(User user) async {
    await ref(user.uid).set(
      {
        'uid': user.uid,
        'status': 'SOLO',
        'coupleId': null,
        'inviteCode': null,
        'pendingPartnerUid': null,
        'relationshipStartDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
