import 'package:flutter_test/flutter_test.dart';
import 'package:ourmoment/main.dart';

void main() {
  testWidgets('스타터 앱 기본 문구가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const StarterApp());
    expect(find.text('OurMoment Starter'), findsOneWidget);
    expect(find.text('앱 내부 코드를 초기화했습니다.'), findsOneWidget);
  });
}
