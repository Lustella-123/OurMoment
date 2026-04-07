# OurMoment

Flutter + Firebase 기반 커플 앱입니다.

## 빠른 시작 (Cloud/로컬 공통)

아래 순서대로 실행하면 Cloud/로컬 환경에서 동일하게 앱 개발을 시작할 수 있습니다.

```bash
# 1) Flutter SDK 설치 + PATH 등록(~/.bashrc)
./scripts/setup_flutter_env.sh

# 2) 프로젝트 의존성 설치(pub get)
./scripts/bootstrap_project.sh

# 3) 분석 + 테스트(기본 테스트 + 이번 이슈 관련 3개 테스트)
./scripts/run_quality_checks.sh

# 4) (선택) Firestore/Storage 규칙·인덱스 배포
./scripts/deploy_firebase_rules.sh
```

## 개발 시 자주 쓰는 명령

```bash
# 앱 실행
flutter run

# iOS 핫리로드 보조 스크립트(필요 시)
bash scripts/run_ios_with_hot_reload.sh
```

## Mac에서 실행 확인 후 TestFlight 업로드

질문하신 대로 **Mac에서 Xcode로 프로젝트를 가져와 실행 확인한 다음, 아래 bash 스크립트를 실행하면 업로드까지 자동화**됩니다.

### 0) 사전 조건

- macOS
- Xcode 설치 및 최초 1회 실행
- Apple Developer Program 가입 계정
- App Store Connect에서 앱 등록 완료 (`com.jscompany.ourmoment`)
- App Store Connect API Key 발급 (권장)
  - `ASC_KEY_ID`
  - `ASC_ISSUER_ID`
  - `.p8` 키 파일 내용(base64)

### 1) 프로젝트 가져오기 + 로컬 실행 확인(Xcode)

1. Cursor(또는 git clone)로 현재 GitHub 브랜치를 Mac에 가져옵니다.
2. 의존성 설치:
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```
3. Xcode에서 `ios/Runner.xcworkspace`를 엽니다.
4. Team/Signing 설정을 확인하고 시뮬레이터 또는 실제 기기에서 1회 실행합니다.
   - 이 단계에서 빌드/서명 문제가 없는지 먼저 확인하는 것이 안전합니다.

### 2) TestFlight fastlane 초기 설정(최초 1회)

```bash
bash scripts/setup_testflight_fastlane.sh
```

실행 후 `ios/fastlane/.env`가 생성됩니다. 아래 값을 입력하세요.

```env
APP_IDENTIFIER=com.jscompany.ourmoment
ASC_KEY_ID=...
ASC_ISSUER_ID=...
ASC_KEY_CONTENT=... # AuthKey_XXXXXX.p8 내용을 base64로 인코딩한 값
APPLE_TEAM_ID=...   # 선택
ITC_TEAM_ID=...     # 선택
```

> base64 예시:
> `base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'`

### 3) TestFlight 업로드

```bash
bash scripts/release_testflight.sh "이번 빌드 변경사항 요약"
```

스크립트가 내부적으로 `bundle exec fastlane ios upload_testflight`를 실행해,
아카이브 후 TestFlight로 업로드합니다.

### 4) 자주 발생하는 문제

- `TestFlight upload is supported only on macOS.`
  - Mac이 아닌 환경에서 실행한 경우입니다.
- `xcodebuild를 찾을 수 없습니다.`
  - Xcode 미설치 또는 Command Line Tools 설정 문제입니다.
- 인증/업로드 실패
  - `ios/fastlane/.env`의 API Key 값 오입력 여부를 먼저 확인하세요.

## 관련 스크립트

- `scripts/setup_testflight_fastlane.sh`: fastlane/Bundler 설치 및 `.env` 템플릿 생성
- `scripts/release_testflight.sh`: TestFlight 업로드 실행

## 최신 반영 요약 (한국어)

가장 최신 작업 브랜치의 변경을 기준 브랜치에 반영했습니다. 이번 정리의 핵심은 아래와 같습니다.

- 인증 전환/세션 처리 안정성 개선 및 관련 테스트 추가
- 캘린더/피드/메모/프로필 화면의 안정화 및 UX 보정
- Firestore 규칙 보강과 커플/캘린더 저장소 로직 보완
- 테마/위젯 정리와 로컬라이제이션 문자열 확장
- Cursor Cloud에서 바로 재현 가능한 셋업/품질검사 스크립트 추가
