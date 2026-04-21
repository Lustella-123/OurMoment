# OurMoment

Flutter + Firebase 기반 커플 앱입니다.

## 로컬에서 검증하기 (분석·테스트·빌드 + E2E 체크리스트)

MVP(탭·기록·피드·Firestore `Moments`·달력·설정)를 **본인 PC에서** 같은 기준으로 확인하려면 아래를 따르세요.

1. **자동 검증 한 번에 실행**
   ```bash
   bash scripts/local_verify.sh
   ```
   APK 빌드를 건너뛰려면: `SKIP_APK_BUILD=1 bash scripts/local_verify.sh`

2. **상세 보고서 + 단계별 실행 방법 + 수동 E2E 체크리스트**  
   → **[docs/LOCAL_VERIFICATION.md](docs/LOCAL_VERIFICATION.md)**

3. **Xcode 시뮬레이터 + 실시간 반영(핫 리로드)** (macOS)  
   → **[docs/IOS_XCODE_SIMULATOR.md](docs/IOS_XCODE_SIMULATOR.md)**  
   - Cursor **Run and Debug**용 `.vscode/launch.json` 포함  
   - `.vscode/settings.json`의 `dart.flutterHotReloadOnSave` (`allDirty`)로 **디버그 중 Dart 저장 시 자동 핫 리로드**

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
