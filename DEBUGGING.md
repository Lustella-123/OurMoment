# Our moment — 디버깅 정보 모음

문제가 생기면 **아래에서 해당 블록만 복사**해 채운 뒤, 그대로 붙여넣으면 원인 파악이 빨라집니다.

---

## 1. 기본 환경 (항상 유용)

아래를 터미널에서 실행한 **전체 출력**을 복사합니다.

```bash
cd "$(git rev-parse --show-toplevel)"
flutter doctor -v
```

**붙여넣기 템플릿:**

```
=== flutter doctor -v ===
(여기에 출력 전체 붙여넣기)
```

---

## 2. 앱·Firebase 식별자 (프로젝트 고정값)

아래는 **우리가 쓰는 값**입니다. 바꿨다면 실제 값으로 수정해서 붙여넣으세요.

**붙여넣기 템플릿:**

```
Firebase 프로젝트 ID: sparta-11632
iOS 번들 ID: com.jscompany.ourmoment
Android applicationId: com.jscompany.ourmoment
```

---

## 3. 빌드 / 실행 오류 (Xcode / Flutter)

**3-1. Flutter CLI로 빌드해 보기**

```bash
cd "$(git rev-parse --show-toplevel)"
flutter clean
flutter pub get
flutter run -v 2>&1 | tail -n 120
```

**붙여넣기 템플릿:**

```
=== 증상 ===
(예: Module 'app_links' not found / 빌드 실패 / 시뮬레이터에서 흰 화면)

=== flutter run -v 마지막 120줄 ===
(여기 붙여넣기)
```

**3-2. iOS Pods (모듈 not found 등)**

```bash
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
cd "$(git rev-parse --show-toplevel)/ios"
pod install
```

**붙여넣기 템플릿:**

```
=== pod install 결과 (끝부분 + 에러 있으면 전체) ===
(여기 붙여넣기)

Xcode에서 연 파일: Runner.xcworkspace / Runner.xcodeproj 중 무엇인지:
```

---

## 4. 로그인 / Auth

**붙여넣기 템플릿:**

```
로그인 수단: Google / Apple / 이메일 중 무엇인지:
증상: (버튼 안 뜸 / 누르면 에러 / 이메일 인증 메일 미수신 등)

=== 에러가 뜨는 경우: 화면 스크린샷 또는 빨간 글씨 전문 ===
(여기 붙여넣기)

=== Flutter 디버그 콘솔에 찍힌 FirebaseAuth 관련 로그 ===
(있으면 전체)
```

**이메일 인증 메일이 안 올 때 추가로:**

```
가입에 사용한 이메일 도메인: (예: gmail.com, naver.com)
스팸/프로모션함 확인 여부: 예 / 아니오
```

---

## 5. Firestore / 초대 코드 연결

**5-1. 규칙 배포 여부**

Firebase Console → Firestore → **규칙** 탭에서, 저장소에 있는 `firebase/firestore.rules`와 **동일한지**, **게시**했는지 적어 주세요.

**붙여넣기 템플릿:**

```
증상: (내 코드 안 보임 / 연결하기 눌러도 실패 / PERMISSION_DENIED 등)

Firestore 규칙 최근 게시 시각(대략):
inviteCodes 컬렉션 규칙이 있는지: 예 / 아니오 / 모름

=== 에러 메시지 전문 (스낵바 또는 로그) ===
(여기 붙여넣기)
```

**5-2. 연결 테스트 시 (두 계정)**

```
A 계정 내 초대 코드(6자): (실제 코드)
B 계정에서 입력한 코드:
B에서 뜬 메시지(한글 그대로):
```

---

## 6. Apple Developer / Sign in with Apple

**붙여넣기 템플릿:**

```
Apple App ID 번들 ID (Explicit): 
Sign in with Apple capability (Xcode): 켜짐 / 안 켜짐
Firebase Auth → Apple 제공업체: 켜짐 / 안 켜짐

=== Apple 로그인 시 에러 문구 ===
(있으면 전문)
```

---

## 7. 한 번에 모아 보내기 (종합 패키지)

문제가 여러 개 겹치면 아래 **한 블록**만 채워내도 됩니다.

```
[Our moment 디버깅 패키지]

1) OS: macOS 버전
2) 증상 한 줄 요약:
3) flutter doctor -v: (전체 붙여넣기)
4) flutter run 또는 Xcode 빌드 에러: (전문)
5) Firebase 프로젝트 ID / 번들 ID 변경 여부: 없음 / 있음(실제값)
6) Firestore 규칙 게시 여부: 함 / 안 함 / 모름
7) 재현 순서: (1. 앱 실행 2. …)
```

---

## 8. 로컬에서 로그만 빠르게 볼 때

```bash
cd "$(git rev-parse --show-toplevel)"
flutter run 2>&1 | tee flutter_run_log.txt
```

문제 난 뒤 `flutter_run_log.txt` 끝부분(에러 근처 80~150줄)을 복사해내도 됩니다.

---

## 9. 민감 정보 주의

- **GoogleService-Info.plist 전체**, **API 키**, **.p8 개인 키**, **비밀번호**는 공개 채팅/이슈에 올리지 마세요.
- 필요하면 키의 **앞 4글자만** 또는 **종류만** 알려 주세요.

---

이 파일은 프로젝트에 포함해 두고, 문제 생길 때마다 **해당 섹션만** 복사해 채우면 됩니다.