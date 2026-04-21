# 로컬 검증 가이드 및 보고서

이 문서는 **Our Moment** MVP(하단 탭, 기록·피드, Firestore `Moments`, 달력·설정 연동)를 **본인 PC에서** 재현·검증할 때 쓰는 절차와, 자동화로 확인한 범위를 정리한 **보고서**입니다.

---

## 1. 보고서 — 무엇을 어디까지 확인했는가

### 1.1 자동 검증 (CI·스크립트와 동일하게 로컬에서 가능)

| 항목 | 명령 | 기대 결과 |
|------|------|------------|
| 의존성 | `flutter pub get` | 오류 없이 완료 |
| 정적 분석 | `flutter analyze` | **No issues found** |
| 단위/위젯 테스트 | `flutter test` | 전부 통과 |
| Android 디버그 빌드 | `flutter build apk --debug` | `build/app/outputs/flutter-apk/app-debug.apk` 생성 |
| (선택) iOS 디버그 빌드 | `flutter build ios --debug` (macOS + Xcode) | Xcode 프로젝트와 함께 빌드 성공 |

위 항목은 **실제 Firebase·로그인 없이도** 대부분 코드 품질과 네이티브 빌드 가능 여부를 보여 줍니다.

### 1.2 수동 E2E (실기기 또는 에뮬레이터 + Firebase 프로젝트 필요)

다음은 **앱이 실행된 뒤** 사용자 흐름으로만 확인 가능합니다.

| 기능 | 확인 방법 | 비고 |
|------|-----------|------|
| 하단 4탭 | 홈화면·피드·달력·설정 라벨 표시 | 아이콘 없이 텍스트만 |
| 홈 → 기록 | 「오늘의 기록 남기기」→ 사진 다중 선택·글 입력 | 커플 연결 후 |
| 저장 | Storage 업로드 + Firestore `Moments` 문서 | 규칙·인덱스 배포 필요 |
| 피드 | 실시간 목록·폴라로이드 그리드 | 같은 `coupleId` |
| 달력 | `table_calendar`, 기록일 하트, 기념일 문구 | `startDate`/`relationshipStart` 등 |
| 설정 | 기념일/생일 표시 스위치 | `SharedPreferences` |

**원격 VM 에뮬레이터**에서는 System UI 지연·ANR 등으로 UI 덤프 E2E가 불안정했습니다. **로컬 Mac/Windows + 실기기 또는 정상 가속 에뮬레이터**에서 아래 체크리스트를 권장합니다.

---

## 2. 사전 준비

### 2.1 공통

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (프로젝트는 `sdk: ^3.8.1` — 설치 후 `flutter --version`으로 호환 확인)
- Git
- 이 저장소 클론 후 프로젝트 루트에서 작업

### 2.2 Firebase (기록·피드·달력 데이터를 진짜로 쓰려면)

- Firebase 콘솔에서 앱이 등록되어 있고, 리포지토리에 `lib/firebase_options.dart`, Android `google-services.json`, iOS `GoogleService-Info.plist`가 맞는 프로젝트를 가리키는지 확인합니다.
- **Firestore·Storage 보안 규칙**과 **복합 인덱스**(`firestore.indexes.json`)를 배포한 환경과 동일하게 맞춥니다. 그렇지 않으면 저장 시 `permission-denied`가 납니다.

### 2.3 Android로 돌릴 때

- [Android Studio](https://developer.android.com/studio) 또는 Android SDK + `cmdline-tools`
- USB 디버깅을 켠 **실제 기기**, 또는 **에뮬레이터** (가능하면 **가속 ON** — Intel HAXM / Apple Silicon은 기본적으로 빠름)
- `flutter doctor`에서 Android toolchain이 ✓인지 확인

### 2.4 iOS로 돌릴 때 (macOS만)

- Xcode + CocoaPods (`cd ios && pod install`)
- Apple 개발자 계정으로 Signing 설정
- `flutter doctor`에서 Xcode가 ✓인지 확인

---

## 3. 로컬 실행 — 단계별 (복사해서 순서대로)

프로젝트 루트 = 저장소 최상위(`pubspec.yaml`이 있는 폴더)입니다.

### 3.1 한 번에 스크립트로 검증 (권장)

```bash
cd /path/to/OurMoment
bash scripts/local_verify.sh
```

기본 동작: `flutter pub get` → `flutter analyze` → `flutter test`  
`ANDROID_HOME` 또는 `ANDROID_SDK_ROOT`가 설정되어 있으면 추가로 `flutter build apk --debug`까지 실행합니다. (Android Studio 설치 시 보통 자동 설정됩니다.)

APK 빌드를 건너뛰려면:

```bash
SKIP_APK_BUILD=1 bash scripts/local_verify.sh
```

### 3.2 수동으로 동일하게 돌리기

```bash
cd /path/to/OurMoment
flutter pub get
flutter analyze
flutter test
```

Android 디버그 APK만 만들기:

```bash
flutter build apk --debug
# 산출물: build/app/outputs/flutter-apk/app-debug.apk
```

### 3.3 에뮬레이터/실기기에 앱 실행 (hot reload 포함)

연결 기기 확인:

```bash
flutter devices
```

Android 에뮬레이터를 켠 뒤:

```bash
flutter run
```

기기가 여러 대면:

```bash
flutter run -d <device_id>
```

iOS 시뮬레이터(macOS):

```bash
open -a Simulator
flutter run -d ios
```

### 3.4 APK만 기기에 설치해서 확인

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.jscompany.ourmoment/.MainActivity
```

(`adb`는 Android SDK `platform-tools`에 있습니다.)

---

## 4. 기능별 수동 체크리스트 (E2E)

로그인·커플 연결이 된 계정으로 진행합니다.

1. **하단 탭**  
   - 홈화면 / 피드 / 달력 / 설정 네 라벨이 보이는지, 탭 전환이 되는지.

2. **홈 → 기록**  
   - 「오늘의 기록 남기기」→ 갤러리에서 사진 여러 장 + 글 입력 → **저장**.  
   - 커플 미연결 시 안내 문구가 나오는지 확인.

3. **피드**  
   - 방금 저장한 글이 보이는지, 사진 장수에 따라 그리드/폴라로이드 레이아웃이 맞는지.

4. **달력**  
   - 기록이 있는 날짜 아래 검은 하트.  
   - 커플 `startDate`(또는 `relationshipStart`/`createdAt`) 기준 100일·주년 라벨.  
   - 기록일과 기념일이 겹치면 하트 위 흰 글씨 레이어.

5. **설정**  
   - 「달력 표시」에서 기념일/생일 스위치를 끄면 달력에서 해당 표시가 사라지는지.

6. **Firestore 콘솔**  
   - `Moments` 컬렉션에 `coupleId`, `caption`, `imageUrls`, `createdAt` 등이 들어갔는지.  
   - Storage 경로 `Moments/{coupleId}/{momentId}/...` 확인.

---

## 5. 자주 나는 문제

| 증상 | 조치 |
|------|------|
| `flutter: command not found` | PATH에 Flutter `bin` 추가, 터미널 재시작 |
| Android 라이선스 | `flutter doctor --android-licenses` |
| iOS `pod install` 실패 | Xcode CLT, `sudo gem install cocoapods` 또는 Bundler로 `ios` 폴더에서 `bundle install` |
| 저장 시 permission-denied | Firestore/Storage 규칙 배포 및 `Moments` 인덱스 배포 |
| 이미지 피커 권한 | Android `AndroidManifest` 권한, iOS `Info.plist` 사진/갤러리 사용 설명 확인 |
| `flutter analyze` 경고 | 최신 `main`에 맞춰 `flutter pub get` 후 재실행 |

---

## 6. 문서·스크립트 위치

| 경로 | 설명 |
|------|------|
| `docs/LOCAL_VERIFICATION.md` | 이 파일 (보고서 + 로컬 절차) |
| `scripts/local_verify.sh` | 로컬 자동 검증 스크립트 |
| `README.md` | 상단 근처에 로컬 검증 링크 추가됨 |

---

*마지막 업데이트: 로컬 검증 문서 및 스크립트 추가 시점 기준.*
