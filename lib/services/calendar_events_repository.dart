import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CoupleCalendarEvent {
  CoupleCalendarEvent({
    required this.id,
    required this.title,
    required this.note,
    required this.dayKey,
    required this.createdBy,
    required this.createdAt,
    required this.timeText,
    required this.colorKey,
    required this.shapeKey,
  });

  final String id;
  final String title;
  final String note;
  final String dayKey;
  final String createdBy;
  final DateTime createdAt;
  final String timeText;
  final String colorKey;
  final String shapeKey;

  factory CoupleCalendarEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    final ts = m['createdAt'] as Timestamp?;
    return CoupleCalendarEvent(
      id: d.id,
      title: m['title'] as String? ?? '',
      note: m['note'] as String? ?? '',
      dayKey: m['dayKey'] as String? ?? '',
      createdBy: m['createdBy'] as String? ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
      timeText: m['timeText'] as String? ?? '',
      colorKey: m['colorKey'] as String? ?? 'rose',
      shapeKey: m['shapeKey'] as String? ?? 'dot',
    );
  }
}

class CalendarEventsRepository {
  CalendarEventsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('calendarEvents');

  String _dayKey(DateTime local) =>
      DateFormat('yyyy-MM-dd').format(DateTime(local.year, local.month, local.day));

  Future<List<CoupleCalendarEvent>> loadEventsInMonth(
    String coupleId,
    DateTime month,
  ) async {
    try {
      final first = DateTime(month.year, month.month, 1);
      final last = DateTime(month.year, month.month + 1, 0);
      final from = _dayKey(first);
      final to = _dayKey(last);
      final snap = await _col(coupleId)
          .where('dayKey', isGreaterThanOrEqualTo: from)
          .where('dayKey', isLessThanOrEqualTo: to)
          .limit(500)
          .get();
      final list = snap.docs.map(CoupleCalendarEvent.fromDoc).toList();
      list.sort((a, b) {
        final byDay = a.dayKey.compareTo(b.dayKey);
        if (byDay != 0) return byDay;
        final byTime = a.timeText.compareTo(b.timeText);
        if (byTime != 0) return byTime;
        return a.createdAt.compareTo(b.createdAt);
      });
      return list;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') return const <CoupleCalendarEvent>[];
      rethrow;
    }
  }

  Future<List<CoupleCalendarEvent>> loadEventsForDay(
    String coupleId,
    DateTime day,
  ) async {
    try {
      final key = _dayKey(day);
      final snap = await _col(coupleId)
          .where('dayKey', isEqualTo: key)
          .limit(200)
          .get();
      final list = snap.docs.map(CoupleCalendarEvent.fromDoc).toList();
      list.sort((a, b) {
        final byTime = a.timeText.compareTo(b.timeText);
        if (byTime != 0) return byTime;
        return a.createdAt.compareTo(b.createdAt);
      });
      return list;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') return const <CoupleCalendarEvent>[];
      rethrow;
    }
  }

  Future<void> addEvent({
    required String coupleId,
    required DateTime day,
    required String title,
    required String note,
    required String timeText,
    required String colorKey,
    required String shapeKey,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    final t = title.trim();
    if (t.isEmpty) return;
    await _col(coupleId).add({
      'title': t.length > 80 ? t.substring(0, 80) : t,
      'note': note.trim().length > 500 ? note.trim().substring(0, 500) : note.trim(),
      'dayKey': _dayKey(day),
      'timeText': _sanitizeTimeText(timeText),
      'colorKey': colorKey,
      'shapeKey': shapeKey,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEvent({
    required String coupleId,
    required String eventId,
    required String title,
    required String note,
    required String timeText,
    required String colorKey,
    required String shapeKey,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    final t = title.trim();
    if (t.isEmpty) return;
    await _col(coupleId).doc(eventId).update({
      'title': t.length > 80 ? t.substring(0, 80) : t,
      'note': note.trim().length > 500 ? note.trim().substring(0, 500) : note.trim(),
      'timeText': _sanitizeTimeText(timeText),
      'colorKey': colorKey,
      'shapeKey': shapeKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    await _col(coupleId).doc(eventId).delete();
  }

  String _sanitizeTimeText(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.length > 5) return t.substring(0, 5);
    return t;
  }
}

