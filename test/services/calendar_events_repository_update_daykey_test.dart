import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourmoment/services/calendar_events_repository.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  test('updateEvent는 dayKey를 새 날짜로 갱신한다', () async {
    final db = FakeFirebaseFirestore();
    const coupleId = 'c1';
    const eventId = 'e1';
    const uid = 'u1';

    await db
        .collection('couples')
        .doc(coupleId)
        .collection('calendarEvents')
        .doc(eventId)
        .set({
          'title': 'before',
          'note': '',
          'dayKey': '2026-04-01',
          'timeText': '09:00',
          'colorKey': 'rose',
          'shapeKey': 'dot',
          'createdBy': uid,
          'createdAt': DateTime(2026, 4, 1),
          'updatedAt': DateTime(2026, 4, 1),
        });

    final repo = CalendarEventsRepository(
      firestore: db,
      auth: _FakeAuth(_FakeUser(uid)),
    );

    await repo.updateEvent(
      coupleId: coupleId,
      eventId: eventId,
      day: DateTime(2026, 4, 7),
      title: 'after',
      note: 'n',
      timeText: '10:30',
      colorKey: 'blue',
      shapeKey: 'dot',
    );

    final snap = await db
        .collection('couples')
        .doc(coupleId)
        .collection('calendarEvents')
        .doc(eventId)
        .get();

    expect(snap.data()?['dayKey'], '2026-04-07');
    expect(snap.data()?['title'], 'after');
  });
}
