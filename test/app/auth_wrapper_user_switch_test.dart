import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourmoment/app/auth_wrapper.dart';
import 'package:ourmoment/services/auth_repository.dart';
import 'package:ourmoment/services/calendar_events_repository.dart';
import 'package:ourmoment/services/couple_repository.dart';
import 'package:ourmoment/services/moments_repository.dart';
import 'package:ourmoment/services/todos_repository.dart';
import 'package:ourmoment/services/user_repository.dart';
import 'package:ourmoment/state/app_settings.dart';
import 'package:ourmoment/state/main_shell_controller.dart';
import 'package:ourmoment/l10n/app_localizations.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;

  @override
  bool get emailVerified => true;

  @override
  List<UserInfo> get providerData => const <UserInfo>[];
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  _FakeAuthRepository(this._stream);
  final Stream<User?> _stream;

  @override
  Stream<User?> userChanges() => _stream;

  @override
  Stream<User?> authStateChanges() => _stream;

  @override
  bool needsEmailVerification(User user) => false;
}

class _RecordingUserRepository extends Fake implements UserRepository {
  final List<String> ensuredUids = <String>[];

  @override
  Future<void> ensureUserProfile(User user) async {
    ensuredUids.add(user.uid);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      const Stream.empty();
}

class _NoopCoupleRepository extends Fake implements CoupleRepository {}

class _NoopMomentsRepository extends Fake implements MomentsRepository {}

class _NoopCalendarEventsRepository extends Fake
    implements CalendarEventsRepository {}

class _NoopTodosRepository extends Fake implements TodosRepository {}

void main() {
  testWidgets('AuthWrapper는 사용자 UID 변경 시 ensureUserProfile를 다시 호출한다', (
    tester,
  ) async {
    final controller = StreamController<User?>.broadcast();
    final authRepo = _FakeAuthRepository(controller.stream);
    final userRepo = _RecordingUserRepository();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(prefs);
    await settings.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepo),
          Provider<UserRepository>.value(value: userRepo),
          Provider<CoupleRepository>(create: (_) => _NoopCoupleRepository()),
          Provider<MomentsRepository>(create: (_) => _NoopMomentsRepository()),
          Provider<CalendarEventsRepository>(
            create: (_) => _NoopCalendarEventsRepository(),
          ),
          Provider<TodosRepository>(create: (_) => _NoopTodosRepository()),
          ChangeNotifierProvider<MainShellController>(
            create: (_) => MainShellController(),
          ),
          ChangeNotifierProvider<AppSettings>.value(value: settings),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthWrapper(),
        ),
      ),
    );

    controller.add(_FakeUser('u1'));
    await tester.pump();
    await tester.pump();
    controller.add(_FakeUser('u2'));
    await tester.pump();

    expect(userRepo.ensuredUids, containsAllInOrder(<String>['u1', 'u2']));
    await controller.close();
  });
}
