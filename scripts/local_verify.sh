#!/usr/bin/env bash
# Our Moment — 로컬에서 pub get / analyze / test / (선택) Android debug APK 빌드
# 사용: 프로젝트 루트에서 bash scripts/local_verify.sh
# APK 빌드 생략: SKIP_APK_BUILD=1 bash scripts/local_verify.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Our Moment local verify (root: $ROOT)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter 가 PATH에 없습니다. https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo ""
echo "==> flutter --version"
flutter --version

echo ""
echo "==> flutter pub get"
flutter pub get

echo ""
echo "==> flutter analyze"
flutter analyze

echo ""
echo "==> flutter test"
flutter test

if [[ "${SKIP_APK_BUILD:-}" == "1" ]]; then
  echo ""
  echo "==> SKIP_APK_BUILD=1 이므로 APK 빌드 생략"
elif [[ -n "${ANDROID_HOME:-}" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  echo ""
  echo "==> flutter build apk --debug (ANDROID_HOME 또는 ANDROID_SDK_ROOT 설정됨)"
  flutter build apk --debug
  echo "APK: $ROOT/build/app/outputs/flutter-apk/app-debug.apk"
else
  echo ""
  echo "==> ANDROID_HOME / ANDROID_SDK_ROOT 가 없어 APK 빌드 생략"
  echo "    Android SDK를 설치·환경변수 설정 후 다시 실행하면 debug APK까지 검증됩니다."
  echo "    분석·테스트만 원하면: SKIP_APK_BUILD=1 bash scripts/local_verify.sh"
fi

echo ""
echo "OK — 로컬 자동 검증 단계 완료."
echo "실기체/에뮬레이터 E2E는: flutter run 후 docs/LOCAL_VERIFICATION.md 체크리스트를 따르세요."
