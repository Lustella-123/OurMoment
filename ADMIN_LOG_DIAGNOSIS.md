# 관리자 로그 진단 파일

앱에서 문제가 생기면 이 파일을 열고, 아래 템플릿에 **로그를 그대로 복사/붙여넣기**해서 확인하세요.

## 1) 붙여넣기 템플릿

```text
[발생 시각]
2026-04-06 10:00

[재현 단계]
1.
2.
3.

[에러 로그 원문]
여기에 콘솔 로그 전체 붙여넣기
```

## 2) 빠른 원인 매핑표

- `No app has been configured yet`
  - Firebase 초기화 순서 문제 가능성. 앱 재실행 후 동일하면 `ios/Runner/AppDelegate.swift`의 Firebase 설정과 `main.dart` 초기화 로직 확인.
- `permission-denied` / `Missing or insufficient permissions`
  - Firestore Rules 미배포 또는 규칙 불일치 가능성. `firebase/firestore.rules` 최신 상태 배포 확인.
- `Undefined symbol: absl::`
  - iOS Pods 링크 문제 가능성. `ios/Podfile`의 static linkage 설정 및 `pod install` 재실행 확인.
- `database is locked`
  - Xcode/Flutter 동시 빌드 충돌. 하나의 빌드만 실행하도록 정리 후 다시 실행.
- `failed-precondition` / `The query requires an index`
  - Firestore 복합 인덱스 필요. `firestore.indexes.json` 반영 후 `firebase deploy --only firestore:indexes` 실행.
- `com.apple.commcenter.coretelephony.xpc` / `RBSAssertionErrorDomain`
  - iOS 시뮬레이터에서 흔한 시스템 로그. 앱 기능 장애와 직접 무관한 경우가 많음.

## 3) 분석 체크리스트

- 같은 에러가 2회 이상 반복되는지 확인
- 로그인/커플 연결 상태에서만 나는 에러인지 확인
- iOS 전용인지(Android/웹도 동일한지) 확인
- 직전 변경 파일(특히 `rules`, `main.dart`, `calendar_screen.dart`) 확인

## 4) 공유용 요약 포맷

아래 4줄만 복사해서 개발자에게 전달:

```text
문제: (한 줄)
시각: (YYYY-MM-DD HH:mm)
재현: (1~3 단계)
핵심 로그: (가장 중요한 3~10줄)
```

