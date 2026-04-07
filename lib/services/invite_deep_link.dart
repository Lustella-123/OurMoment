/// 커스텀 스킴: `ourmoment://invite?code=XXXXXX`
String? parseInviteCodeFromUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'ourmoment') return null;
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return null;
  return code.toUpperCase();
}

String inviteDeepLink(String inviteCode) {
  final c = inviteCode.toUpperCase();
  return 'ourmoment://invite?code=$c';
}
