// GoogleService-Info.plist 기준으로 생성됨.
// Android 앱을 Firebase에 추가하면 google-services.json으로 android 항목을 채우거나
// `flutterfire configure`로 다시 생성하세요.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions는 이 플랫폼용으로 아직 없습니다.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA17RROPmiQ0BpH3WLBwPgdfER1nf0lcKA',
    appId: '1:529018795002:ios:e84e2d2d953294cd46ea43',
    messagingSenderId: '529018795002',
    projectId: 'sparta-11632',
    storageBucket: 'sparta-11632.firebasestorage.app',
    iosBundleId: 'com.jscompany.ourmoment',
  );

  /// Firebase 콘솔에서 Android 앱 등록 후 `google-services.json`의 mobilesdk_app_id로 교체.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA17RROPmiQ0BpH3WLBwPgdfER1nf0lcKA',
    appId: '1:529018795002:android:REGISTER_ANDROID_APP_IN_CONSOLE',
    messagingSenderId: '529018795002',
    projectId: 'sparta-11632',
    storageBucket: 'sparta-11632.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA17RROPmiQ0BpH3WLBwPgdfER1nf0lcKA',
    appId: '1:529018795002:ios:e84e2d2d953294cd46ea43',
    messagingSenderId: '529018795002',
    projectId: 'sparta-11632',
    storageBucket: 'sparta-11632.firebasestorage.app',
    iosBundleId: 'com.jscompany.ourmoment',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyA17RROPmiQ0BpH3WLBwPgdfER1nf0lcKA',
    appId: '1:529018795002:web:ourmomentlinuxmvp',
    messagingSenderId: '529018795002',
    projectId: 'sparta-11632',
    storageBucket: 'sparta-11632.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA17RROPmiQ0BpH3WLBwPgdfER1nf0lcKA',
    appId: '1:529018795002:web:ourmomentlinuxmvp',
    messagingSenderId: '529018795002',
    projectId: 'sparta-11632',
    authDomain: 'sparta-11632.firebaseapp.com',
    storageBucket: 'sparta-11632.firebasestorage.app',
  );
}
