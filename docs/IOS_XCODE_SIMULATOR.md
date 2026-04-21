# Xcode + iOS 시뮬레이터 + 실시간 반영(핫 리로드)

macOS에서 **시뮬레이터는 Xcode 쪽에서 켜고**, 앱은 **Flutter(`flutter run`)**로 올리면 **코드 수정 → 저장 → 즉시 반영**이 가능합니다. (Flutter의 **Hot reload** / **Hot restart**)

---

## 0. 초보용 — 먼저 이것만 이해하면 됩니다

### Xcode에는 “브랜치”가 없어요

- **Git 브랜치**(`main`, `cursor/...` 같은 것)는 **Cursor / 터미널 / Git**에서만 바꿉니다.
- **Xcode**는 “브랜치 선택 화면”이 없습니다. Xcode가 여는 건 **맥에 있는 폴더의 파일**뿐이에요.
- 그래서 **Cursor에서 어떤 브랜치로 checkout 했는지**와 **Xcode가 연 폴더가 같은지**가 맞아야 합니다.
  - 작업은 항상 **같은 OurMoment 폴더 하나**에서 하세요.
  - 예전에 다른 위치에 복사해 둔 폴더를 Xcode로 열면, **예전 코드**가 보일 수 있어요.

### 시뮬레이터에서 “앱이 이미 떠 있는 것 같다”면

- 시뮬레이터는 **예전에 설치해 둔 앱**을 그대로 두는 경우가 많아요. 그게 **최신 코드**인지는 별개입니다.
- **지금 수정 중인 코드**로 돌리려면, 아래 **§4**처럼 터미널에서 **`flutter run -d ios`** 를 **한 번 더** 실행하세요. 그때 새로 빌드해서 덮어씁니다.

### Xcode에서 시뮬레이터만 켜는 방법 (클릭 순서)

Xcode 앱이 **켜져 있어야** 메뉴가 보입니다.

1. **Spotlight** 열기: 키보드 `Command(⌘) + Space`
2. **Simulator** 또는 **Xcode** 입력 후 Xcode 실행
3. 맨 위 메뉴막대에서 **`Xcode`** 클릭 (화면 왼쪽 위, 사과 로고 옆)
4. **`Open Developer Tool`** 에 마우스를 올리기
5. **`Simulator`** 클릭

잠시 후 **아이폰 같은 창**이 하나 뜨면 시뮬레이터가 켜진 겁니다. (앱이 자동으로 깔리는 건 아닙니다. 예전에 깔아 둔 앱이 보일 수는 있어요.)

**다른 방법:** 터미널을 연 다음 한 줄만 입력:

```bash
open -a Simulator
```

역시 **아이폰 창**이 뜨면 성공입니다.

---

## 1. 한 줄 요약

1. **시뮬레이터 실행**: Xcode 메뉴 또는 `open -a Simulator`  
2. **프로젝트 루트**에서 `flutter devices`로 시뮬레이터 **이름 또는 id** 확인 후 `flutter run -d <id>` 실행 (`flutter run -d ios`는 환경에 따라 **기기를 못 찾을 수 있음**)  
3. 터미널이 Flutter에 붙어 있는 동안 **`r`** = 핫 리로드, **`R`** = 핫 리스타트  
4. (선택) Cursor에서 **Run and Debug** — `.vscode/launch.json`은 기기를 강제하지 않음(실행 시 시뮬레이터 선택)

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
flutter devices
```

**`flutter run -d ios`가 “No supported devices… matching 'ios'” 이면** `-d ios` 대신 목록에 나온 **id** 또는 **기기 이름**을 씁니다.

```bash
flutter run -d 5C12B3E5-505F-44AB-A5E7-73BA3367C3E0   # 예: flutter devices 의 id
# 또는
flutter run -d "iPhone 16 Pro Max"
```

시뮬레이터가 **하나만** 켜져 있으면 보통 `flutter run` 만으로도 잡히는 경우가 많습니다.

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
