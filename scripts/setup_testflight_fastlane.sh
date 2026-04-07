#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT/ios"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "TestFlight fastlane setup is supported only on macOS."
  exit 1
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "Ruby가 설치되어 있지 않습니다. Xcode Command Line Tools를 먼저 설치하세요."
  exit 1
fi

cd "$IOS_DIR"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler가 없어 설치합니다..."
  gem install bundler --no-document
fi

echo "bundle install 실행..."
bundle install

ENV_FILE="$IOS_DIR/fastlane/.env"
DEFAULT_ENV_FILE="$IOS_DIR/fastlane/.env.default"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$DEFAULT_ENV_FILE" "$ENV_FILE"
  echo "생성됨: $ENV_FILE"
  echo "ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_CONTENT 값을 입력해 주세요."
else
  echo "이미 존재: $ENV_FILE"
fi

echo ""
echo "다음 단계:"
echo "  1) ios/fastlane/.env 값 입력"
echo "  2) bash scripts/release_testflight.sh \"릴리즈 노트\""
