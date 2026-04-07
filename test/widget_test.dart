import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourmoment/state/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppSettings 기본 언어 ko', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(prefs);
    await settings.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(body: Text(settings.languageCode)),
        ),
      ),
    );

    expect(find.text('ko'), findsOneWidget);
  });
}
