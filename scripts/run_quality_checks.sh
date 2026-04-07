#!/usr/bin/env bash
# 코드 품질/테스트 실행 스크립트
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[error] flutter 명령을 찾지 못했습니다. 먼저 scripts/setup_flutter_env.sh 실행 후 터미널을 다시 여세요."
  exit 1
fi

echo "[1/4] flutter --version"
flutter --version

echo "[2/4] flutter pub get"
flutter pub get

echo "[3/4] flutter analyze"
flutter analyze

echo "[4/4] focused tests"
flutter test test/services/couple_repository_invite_claim_test.dart
flutter test test/services/calendar_events_repository_update_daykey_test.dart
flutter test test/app/auth_wrapper_user_switch_test.dart

echo "[done] 품질 검사/핵심 테스트 실행 완료"
