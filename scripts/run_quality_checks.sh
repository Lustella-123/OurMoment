#!/usr/bin/env bash
# 코드 품질/테스트 실행 스크립트
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.local/flutter}"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
mkdir -p "$PUB_CACHE"

ensure_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    return 0
  fi

  # Cloud 에이전트의 기본 설치 위치를 자동으로 PATH에 반영.
  if [[ -x "$FLUTTER_HOME/bin/flutter" ]]; then
    export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
  fi

  if command -v flutter >/dev/null 2>&1; then
    return 0
  fi

  echo "[info] flutter 미탐지: scripts/setup_flutter_env.sh 실행으로 자동 설치/초기화합니다."
  bash "$ROOT/scripts/setup_flutter_env.sh"
  export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

  if ! command -v flutter >/dev/null 2>&1; then
    echo "[error] flutter 설정에 실패했습니다. scripts/setup_flutter_env.sh 로그를 확인해 주세요."
    exit 1
  fi
}

ensure_flutter

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
