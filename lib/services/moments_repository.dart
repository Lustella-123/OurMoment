import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';

enum UploadTier { free, premium }

class CoupleMoment {
  CoupleMoment({
    required this.id,
    required this.authorUid,
    required this.caption,
    required this.createdAt,
    required this.dayKey,
    this.imageUrls = const [],
    this.likeCount = 0,
  });

  final String id;
  final String authorUid;
  final String caption;
  final DateTime createdAt;
  final String dayKey;
  final List<String> imageUrls;
  final int likeCount;

  factory CoupleMoment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) {
      return CoupleMoment(
        id: d.id,
        authorUid: '',
        caption: '',
        createdAt: DateTime.now(),
        dayKey: '',
      );
    }
    final ts = m['createdAt'] as Timestamp?;
    final urls = <String>[];
    final raw = m['imageUrls'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String && e.isNotEmpty) urls.add(e);
      }
    }
    if (urls.isEmpty) {
      final single = m['imageUrl'] as String?;
      if (single != null && single.isNotEmpty) urls.add(single);
    }
    return CoupleMoment(
      id: d.id,
      authorUid: m['authorUid'] as String? ?? '',
      caption: m['caption'] as String? ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
      dayKey: m['dayKey'] as String? ?? '',
      imageUrls: urls,
      likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MomentComment {
  MomentComment({
    required this.id,
    required this.authorUid,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String text;
  final DateTime createdAt;

  factory MomentComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) {
      return MomentComment(
        id: d.id,
        authorUid: '',
        text: '',
        createdAt: DateTime.now(),
      );
    }
    final ts = m['createdAt'] as Timestamp?;
    return MomentComment(
      id: d.id,
      authorUid: m['authorUid'] as String? ?? '',
      text: m['text'] as String? ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}

/// 커플 공유 순간: 피드·일기·달력이 동일 컬렉션을 사용합니다.
class MomentsRepository {
  MomentsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> momentsCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('moments');

  String _dayKey(DateTime local) => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(local.year, local.month, local.day));

  /// 갤러리 원본이 커도 업로드 용량을 줄이기 위해 재압축합니다.
  ///
  /// - 프리미엄: 화질 저하를 최소화하며 2K 이하/quality 84
  /// - 무료: 비용 절감을 위해 1K 이하/quality 66
  static Future<Uint8List> compressForUpload(
    Uint8List raw, {
    UploadTier tier = UploadTier.free,
  }) async {
    if (raw.isEmpty) return raw;
    try {
      final isPremium = tier == UploadTier.premium;
      final targetMax = isPremium ? 2048 : 1024;
      final targetQuality = isPremium ? 84 : 66;
      final out = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: targetMax,
        minHeight: targetMax,
        quality: targetQuality,
      );
      if (out.isNotEmpty) return Uint8List.fromList(out);
    } catch (e) {
      debugPrint('compressForUpload: $e');
    }
    return raw;
  }

  Stream<List<CoupleMoment>> watchMoments(String coupleId, {int limit = 80}) {
    return momentsCol(coupleId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(CoupleMoment.fromDoc).toList());
  }

  Future<void> refreshMoments(String coupleId, {int limit = 80}) async {
    try {
      await momentsCol(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
    } on FirebaseException catch (e) {
      // 오프라인에서는 캐시를 우선 사용하고, UI에서 재시도 선택지를 보여준다.
      if (e.code != 'unavailable') rethrow;
      await momentsCol(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 6));
    }
  }

  Future<void> bumpLoveTemperature(String coupleId, int delta) async {
    if (delta <= 0) return;
    await _db.runTransaction((txn) async {
      final ref = _db.collection('couples').doc(coupleId);
      final snap = await txn.get(ref);
      final v = (snap.data()?['loveTemperature'] as num?)?.toInt() ?? 0;
      final next = min(kLoveTemperatureMax, v + delta);
      txn.update(ref, {
        'loveTemperature': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static const int kMaxPhotosPerMoment = 12;

  Future<CoupleMoment> createMoment({
    required String coupleId,
    required String caption,
    required List<Uint8List>? imageBytesList,
    required UploadTier uploadTier,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_authenticated');

    final docRef = momentsCol(coupleId).doc();
    final momentId = docRef.id;
    final now = DateTime.now();
    final day = _dayKey(now);

    final urls = <String>[];
    if (imageBytesList != null && imageBytesList.isNotEmpty) {
      var i = 0;
      for (final raw in imageBytesList) {
        if (raw.isEmpty) continue;
        if (urls.length >= kMaxPhotosPerMoment) break;
        final compressed = await compressForUpload(raw, tier: uploadTier);
        final ref = _storage.ref(
          'couples/$coupleId/moments/$momentId/img_$i.jpg',
        );
        await ref
            .putData(compressed, SettableMetadata(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 20));
        urls.add(
          await ref.getDownloadURL().timeout(const Duration(seconds: 10)),
        );
        i++;
      }
    }

    await docRef
        .set({
          'authorUid': user.uid,
          'caption': caption.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'dayKey': day,
          'likeCount': 0,
          'photoCount': urls.length,
          if (urls.isNotEmpty) 'imageUrls': urls,
        })
        .timeout(const Duration(seconds: 12));

    await bumpLoveTemperature(coupleId, kLoveTempDeltaNewMoment);

    final snap = await docRef.get();
    return CoupleMoment.fromDoc(snap);
  }

  Future<void> toggleLike(String coupleId, String momentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final likeRef = momentsCol(
      coupleId,
    ).doc(momentId).collection('likes').doc(uid);
    final momentRef = momentsCol(coupleId).doc(momentId);

    var didAdd = false;
    await _db.runTransaction((txn) async {
      final likeSnap = await txn.get(likeRef);
      final mSnap = await txn.get(momentRef);
      if (!mSnap.exists) return;
      final count = (mSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
      if (likeSnap.exists) {
        txn.delete(likeRef);
        txn.update(momentRef, {
          'likeCount': max(0, count - 1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (count >= 2) return;
        txn.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        txn.update(momentRef, {
          'likeCount': count + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        didAdd = true;
      }
    });
    if (didAdd) {
      await bumpLoveTemperature(coupleId, kLoveTempDeltaLike);
    }
  }

  Future<bool> userHasLiked(String coupleId, String momentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final snap = await momentsCol(
      coupleId,
    ).doc(momentId).collection('likes').doc(uid).get();
    return snap.exists;
  }

  Stream<bool> watchUserLiked(String coupleId, String momentId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(false);
    }
    return momentsCol(coupleId)
        .doc(momentId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists);
  }

  Stream<List<MomentComment>> watchComments(String coupleId, String momentId) {
    return momentsCol(coupleId)
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(MomentComment.fromDoc).toList());
  }

  Future<void> addComment(String coupleId, String momentId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final t = text.trim();
    if (t.isEmpty) return;
    await momentsCol(coupleId).doc(momentId).collection('comments').add({
      'authorUid': user.uid,
      'text': t.length > 2000 ? t.substring(0, 2000) : t,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await bumpLoveTemperature(coupleId, kLoveTempDeltaComment);
  }

  Future<void> deleteComment(
    String coupleId,
    String momentId,
    String commentId,
  ) async {
    await momentsCol(
      coupleId,
    ).doc(momentId).collection('comments').doc(commentId).delete();
  }

  Future<List<CoupleMoment>> loadMomentsForDay(
    String coupleId,
    DateTime day,
  ) async {
    final key = _dayKey(day);
    final snap = await momentsCol(coupleId)
        .where('dayKey', isEqualTo: key)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(CoupleMoment.fromDoc).toList();
  }

  Future<Set<DateTime>> loadDaysWithMomentsInMonth(
    String coupleId,
    DateTime month,
  ) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final from = _dayKey(first);
    final to = _dayKey(last);
    final snap = await momentsCol(coupleId)
        .where('dayKey', isGreaterThanOrEqualTo: from)
        .where('dayKey', isLessThanOrEqualTo: to)
        .get();
    final out = <DateTime>{};
    for (final d in snap.docs) {
      final key = d.data()['dayKey'] as String?;
      if (key == null || key.length != 10) continue;
      final p = key.split('-');
      if (p.length != 3) continue;
      out.add(
        DateTime(
          int.tryParse(p[0]) ?? 0,
          int.tryParse(p[1]) ?? 0,
          int.tryParse(p[2]) ?? 0,
        ),
      );
    }
    return out;
  }

  Future<Map<String, List<String>>> loadPhotoUrlsByDayInMonth(
    String coupleId,
    DateTime month,
  ) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final from = _dayKey(first);
    final to = _dayKey(last);
    final snap = await momentsCol(coupleId)
        .where('dayKey', isGreaterThanOrEqualTo: from)
        .where('dayKey', isLessThanOrEqualTo: to)
        .get();
    final moments =
        snap.docs
            .map(CoupleMoment.fromDoc)
            .where((m) => m.imageUrls.isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final out = <String, List<String>>{};
    for (final m in moments) {
      if (m.dayKey.isEmpty) continue;
      out.putIfAbsent(m.dayKey, () => <String>[]).addAll(m.imageUrls);
    }
    return out;
  }

  Future<void> deleteMoment(String coupleId, CoupleMoment m) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || m.authorUid != uid) return;
    for (final url in m.imageUrls) {
      if (url.isEmpty) continue;
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        debugPrint('Storage delete: $e');
      }
    }
    final momentRef = momentsCol(coupleId).doc(m.id);
    final likes = await momentRef.collection('likes').get();
    final comments = await momentRef.collection('comments').get();
    final batch = _db.batch();
    for (final d in likes.docs) {
      batch.delete(d.reference);
    }
    for (final d in comments.docs) {
      batch.delete(d.reference);
    }
    batch.delete(momentRef);
    await batch.commit();
  }
}
