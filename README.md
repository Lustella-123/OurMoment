# OurMoment Starter

기존 앱 기능 코드를 제거하고, 새로 시작할 수 있도록 최소 골격만 남긴 Flutter + Firebase 스타터입니다.

## 현재 남겨둔 것

- `pubspec.yaml`의 기존 의존성
- `lib/firebase_options.dart` (Firebase / Storage 설정)
- `lib/main.dart` 최소 시작 화면
  - 앱 시작 시 Firebase 초기화 시도
  - 현재 프로젝트 ID / Storage 버킷 표시

## 빠른 시작

```bash
flutter pub get
flutter run
```

## 구조

```text
lib/
  firebase_options.dart
  main.dart
test/
  widget_test.dart
```

이 상태를 기준으로 필요한 화면, 상태관리, 도메인 로직을 새로 추가하면 됩니다.
