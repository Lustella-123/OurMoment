import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  GoogleSignIn? _googleSignIn;

  static const String _iosBundleId = 'com.jscompany.ourmoment';
  static const String _authContinueUrl = 'https://sparta-11632.firebaseapp.com';

  /// 인증 메일 링크가 iOS 앱과 연결되도록 설정 (스팸·수신 문제 완화에도 도움되는 경우 있음)
  ActionCodeSettings get _emailActionCodeSettings => ActionCodeSettings(
    url: _authContinueUrl,
    handleCodeInApp: true,
    iOSBundleId: _iosBundleId,
    androidPackageName: 'com.jscompany.ourmoment',
    androidInstallApp: true,
    androidMinimumVersion: '21',
  );

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// 이메일·비밀번호 가입자는 반드시 인증 메일을 통과해야 함.
  bool needsEmailVerification(User user) {
    final hasPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    return hasPassword && !user.emailVerified;
  }

  Future<UserCredential> signInWithGoogle() async {
    final client = _googleSignIn ??= GoogleSignIn();
    final account = await client.signIn();
    if (account == null) {
      throw StateError('google_cancelled');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    return _auth.signInWithCredential(oauthCredential);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.sendEmailVerification(_emailActionCodeSettings);
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification(_emailActionCodeSettings);
  }

  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  Future<void> signOut() async {
    final signOuts = <Future<void>>[_auth.signOut()];
    final client = _googleSignIn;
    if (client != null) {
      signOuts.add(client.signOut());
    }
    await Future.wait(signOuts);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: _emailActionCodeSettings,
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
