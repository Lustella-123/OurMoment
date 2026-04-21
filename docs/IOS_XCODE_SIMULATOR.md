# Xcode + iOS 시뮬레이터 + 실시간 반영(핫 리로드)

macOS에서 **시뮬레이터는 Xcode 쪽에서 켜고**, 앱은 **Flutter(`flutter run`)**로 올리면 **코드 수정 → 저장 → 즉시 반영**이 가능합니다. (Flutter의 **Hot reload** / **Hot restart**)

---

## 1. 한 줄 요약

1. **시뮬레이터 실행**: Xcode 메뉴 또는 `open -a Simulator`  
2. **프로젝트 루트**에서 `flutter run -d ios` (또는 Cursor에서 **Run and Debug**)  
3. 터미널이 Flutter에 붙어 있는 동안 **`r`** = 핫 리로드, **`R`** = 핫 리스타트  
4. (선택) Cursor에서 **저장할 때마다 자동 핫 리로드** — 아래 §5

---

## 2. 사전 준비 (최초 1회)

| 항목 | 설명 |
|------|------|
| Xcode | App Store에서 설치 후 **1회 실행** (라이선스·컴포넌트 동의) |
| CocoaPods | 터미널: `cd ios && pod install && cd ..` |
| Flutter | `flutter doctor`에서 **Xcode**·**CocoaPods**가 ✓인지 확인 |
| 서명 | Xcode에서 `ios/Runner.xcworkspace` 열고 **Signing & Capabilities**에 Team 지정 (시뮬레이터는 보통 자동으로 됨) |

---

## 3. 시뮬레이터 켜기 (Xcode 사용)

**방법 A — Xcode 메뉴**

1. Xcode 실행  
2. 상단 메뉴 **Xcode → Open Developer Tool → Simulator**  
3. 시뮬레이터가 뜨면 **Hardware → Device**에서 기기 종류·iOS 버전 선택 가능  

**방법 B — 터미널**

```bash
open -a Simulator
```

이후 시뮬레이터 창이 보이면 됩니다.

---

## 4. 앱 실행 + 실시간 반영 (터미널)

프로젝트 루트(`pubspec.yaml` 있는 폴더)에서:

```bash
cd /path/to/OurMoment
flutter pub get
flutter devices          # "iPhone 15" 등 시뮬레이터가 보이는지 확인
flutter run -d ios       # 연결된 iOS 시뮬레이터 중 하나로 실행
```

특정 시뮬레이터 ID로 고정하려면:

```bash
flutter devices          # id 열 복사
flutter run -d <기기_ID>
```

### 4.1 빌드가 끝난 뒤 — 키보드 단축키 (실시간 적용)

`flutter run`으로 붙은 **그 터미널**에 포커스를 두고:

| 입력 | 동작 |
|------|------|
| **`r`** | **Hot reload** — 대부분 UI·로직 변경이 **몇 초 안에** 반영 |
| **`R`** | **Hot restart** — 상태 전체 초기화에 가깝게 다시 시작 |
| **`q`** | 종료 |

> **Hot reload**가 안 되는 변경(예: `main()` 초기화·일부 네이티브 플러그인 변경)은 **`R`** 또는 앱 완전 재실행이 필요할 수 있습니다.

### 4.2 자동으로 첫 핫 리로드까지 (선택)

`expect`가 있으면(맥에서 `brew install expect`):

```bash
bash scripts/run_ios_with_hot_reload.sh
```

또는 기기 ID를 넘깁니다:

```bash
bash scripts/run_ios_with_hot_reload.sh <flutter devices에 나온 id>
```

스크립트가 `flutter run` 후 첫 프롬프트에서 **`r` 한 번**을 보내고, 이후에는 같은 터미널에서 `r` / `R` / `q`를 직접 쓰면 됩니다.

---

## 5. Cursor / VS Code에서 시뮬레이터 + 저장 시 자동 반영

### 5.1 확장

- [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)  
- 설치 시 **Flutter** 포함

### 5.2 실행

1. 시뮬레이터를 먼저 켭니다 (`open -a Simulator` 또는 Xcode).  
2. Cursor 왼쪽 **Run and Debug**(또는 `F5`).  
3. **「Our Moment (iOS Simulator)」** 선택 후 실행.

구성은 저장소의 `.vscode/launch.json`에 있습니다.

### 5.3 저장할 때마다 핫 리로드 (실시간에 가깝게)

저장소의 `.vscode/settings.json`에 다음이 들어 있습니다.

- `"dart.flutterHotReloadOnSave": "allDirty"` — Flutter **디버그 중** Dart 파일을 **저장할 때**(변경이 있을 때) 자동 핫 리로드

다른 값: `manual`(수동 저장만), `never`(끔), `all` 등 — [Dart Code 설정 문서](https://dartcode.org/docs/settings/) 참고.

> 전역으로 쓰려면 Cursor **Settings(JSON)**에 동일 키를 넣어도 됩니다.

---

## 6. “Xcode만으로 Run” 할 때 (참고)

`ios/Runner.xcworkspace`를 Xcode에서 열고 **▶ Run**으로도 시뮬레이터에 올릴 수 있습니다.  
다만 이렇게 올린 빌드는 **Xcode가 빌드한 네이티브 앱**이라, **일반적인 Flutter 핫 리로드 흐름(`flutter run` 터미널의 `r`)과는 별개**입니다.

**Flutter 개발 중 실시간 UI 반영**을 쓰려면:

- **`flutter run -d ios`** (또는 Cursor Run and Debug의 Dart 구성)을 쓰는 것을 권장합니다.

Xcode로만 Run한 상태에서 터미널을 추가로 쓰려면, 같은 시뮬레이터에 대해 `flutter attach`가 가능한 경우가 있으나, 보통은 **`flutter run`으로 다시 띄우는 것**이 단순합니다.

---

## 7. 자주 나는 문제

| 증상 | 조치 |
|------|------|
| `No devices found` | Simulator 실행 후 `flutter devices` 재확인 |
| Signing 오류 | Xcode에서 Runner 타깃 Signing 팀 선택 |
| `pod install` 실패 | `sudo gem install cocoapods` 또는 Bundler로 `cd ios && bundle install && bundle exec pod install` |
| 핫 리로드가 안 됨 | `R` 후 재시도, 또는 `q`로 끄고 `flutter run` 다시 실행 |
| 시뮬레이터가 느림 | 기기 RAM 늘리기(Simulator → Device → Erase Content는 초기화이므로 주의), Xcode 재시작 |

---

*관련: [LOCAL_VERIFICATION.md](./LOCAL_VERIFICATION.md) — 전체 로컬 검증·Android APK 절차*
