import 'package:flutter_test/flutter_test.dart';
import 'package:ourmoment/services/couple_repository.dart';

void main() {
  test('invite claim 에러 enum 존재 확인', () {
    expect(CoupleInviteError.inviteAlreadyClaimed, isA<CoupleInviteError>());
  });
}
