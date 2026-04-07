#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[bootstrap] 시작: Flutter SDK/프로젝트 의존성 준비"

bash "$ROOT/scripts/setup_flutter_env.sh"

if ! command -v flutter >/dev/null 2>&1; then
  export FLUTTER_HOME="${HOME}/flutter"
  export PATH="${FLUTTER_HOME}/bin:${PATH}"
fi

flutter --version
flutter pub get

echo "[bootstrap] 완료: flutter pub get 성공"
