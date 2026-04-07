import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';

class MonthlyPhotoLimitExceededException implements Exception {
  MonthlyPhotoLimitExceededException({
    required this.limit,
    required this.usedPhotos,
    required this.pendingPhotos,
  });

  final int limit;
  final int usedPhotos;
  final int pendingPhotos;

  int get nextTotal => usedPhotos + pendingPhotos;

  @override
  String toString() => 'monthly_photo_limit_exceeded';
}

class CoupleUploadPolicy {
  const CoupleUploadPolicy({
    required this.isPremium,
    required this.monthlyUsedPhotos,
    required this.monthlyLimit,
  });

  final bool isPremium;
  final int monthlyUsedPhotos;
  final int monthlyLimit;

  bool canUpload(int pendingPhotos) {
    if (isPremium) return true;
    return monthlyUsedPhotos + pendingPhotos <= monthlyLimit;
  }
}

class CoupleUploadPolicyService {
  CoupleUploadPolicyService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _momentsCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('moments');

  String _dayKey(DateTime local) => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(local.year, local.month, local.day));

  Future<CoupleUploadPolicy> fetchPolicy({
    required String coupleId,
    DateTime? now,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_authenticated');

    final coupleSnap = await _db.collection('couples').doc(coupleId).get();
    final isPremium = _isPremiumCouple(coupleSnap.data());
    if (isPremium) {
      return const CoupleUploadPolicy(
        isPremium: true,
        monthlyUsedPhotos: 0,
        monthlyLimit: kFreeMonthlyPhotoLimit,
      );
    }

    final used = await _loadMonthlyPhotoCount(coupleId, now: now);
    return CoupleUploadPolicy(
      isPremium: false,
      monthlyUsedPhotos: used,
      monthlyLimit: kFreeMonthlyPhotoLimit,
    );
  }

  Future<void> assertCanUpload({
    required CoupleUploadPolicy policy,
    required int pendingPhotos,
  }) async {
    if (policy.canUpload(pendingPhotos)) return;
    throw MonthlyPhotoLimitExceededException(
      limit: policy.monthlyLimit,
      usedPhotos: policy.monthlyUsedPhotos,
      pendingPhotos: pendingPhotos,
    );
  }

  Future<int> _loadMonthlyPhotoCount(String coupleId, {DateTime? now}) async {
    final base = now ?? DateTime.now();
    final first = DateTime(base.year, base.month, 1);
    final last = DateTime(base.year, base.month + 1, 0);
    final from = _dayKey(first);
    final to = _dayKey(last);

    final snap = await _momentsCol(coupleId)
        .where('dayKey', isGreaterThanOrEqualTo: from)
        .where('dayKey', isLessThanOrEqualTo: to)
        .get();

    var total = 0;
    for (final d in snap.docs) {
      final m = d.data();
      final explicit = (m['photoCount'] as num?)?.toInt();
      if (explicit != null && explicit >= 0) {
        total += explicit;
        continue;
      }

      final urls = m['imageUrls'];
      if (urls is List) {
        total += urls.whereType<String>().where((e) => e.isNotEmpty).length;
        continue;
      }

      final single = m['imageUrl'];
      if (single is String && single.isNotEmpty) {
        total += 1;
      }
    }
    return total;
  }

  bool _isPremiumCouple(Map<String, dynamic>? data) {
    if (data == null) return false;

    bool readBool(dynamic value) => value is bool && value;

    if (readBool(data['isPremium']) || readBool(data['premium'])) return true;
    final plan = data['plan'];
    if (plan is String && plan.toLowerCase() == 'premium') return true;

    final billing = data['billing'];
    if (billing is Map<String, dynamic>) {
      if (readBool(billing['isPremium']) || readBool(billing['active'])) {
        return true;
      }
      final billingPlan = billing['plan'];
      if (billingPlan is String && billingPlan.toLowerCase() == 'premium') {
        return true;
      }
    }

    final subscription = data['subscription'];
    if (subscription is Map<String, dynamic>) {
      if (readBool(subscription['isPremium']) || readBool(subscription['active'])) {
        return true;
      }
      final status = subscription['status'];
      if (status is String) {
        final normalized = status.toLowerCase();
        if (normalized == 'active' ||
            normalized == 'premium' ||
            normalized == 'trialing') {
          return true;
        }
      }
    }

    return false;
  }
}
