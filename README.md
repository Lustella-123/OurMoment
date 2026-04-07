# ourmoment

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## TestFlight release automation (fastlane)

This repository includes a fastlane pipeline for TestFlight upload on macOS.

### 1) One-time setup

```bash
bash scripts/setup_testflight_fastlane.sh
```

This script does:
- `bundle install` based on `ios/Gemfile`
- Copies `ios/fastlane/.env.default` to `ios/fastlane/.env` (only if missing)

### 2) Fill environment values

Open `ios/fastlane/.env` and fill values.

Required (recommended: App Store Connect API Key):
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_PATH` (absolute path recommended)

Optional:
- `APP_IDENTIFIER` (default: `com.jscompany.ourmoment`)
- `APPLE_ID`
- `APP_STORE_CONNECT_TEAM_ID`
- `DEVELOPER_PORTAL_TEAM_ID`

### 3) Upload to TestFlight

```bash
bash scripts/release_testflight.sh "Release notes for this build"
```

Internally this runs:
- `ios/fastlane/Fastfile` → `ios upload_testflight`

Flow:
1. Increment build number
2. `flutter build ipa --release --export-method app-store`
3. Upload latest IPA to TestFlight

### Notes

- TestFlight upload only works on **macOS + Xcode**.
- Secret values (`ios/fastlane/.env`) are ignored by git via `.gitignore`.
