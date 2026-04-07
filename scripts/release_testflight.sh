#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT/ios"
CHANGELOG="${1:-Automated TestFlight upload}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "TestFlight upload is supported only on macOS."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild를 찾을 수 없습니다. Xcode를 설치하고 실행해 주세요."
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "bundler를 찾을 수 없습니다. 먼저 bash scripts/setup_testflight_fastlane.sh 를 실행하세요."
  exit 1
fi

if [[ ! -f "$IOS_DIR/fastlane/.env" ]]; then
  echo "ios/fastlane/.env 파일이 없습니다."
  echo "먼저 bash scripts/setup_testflight_fastlane.sh 를 실행해 주세요."
  exit 1
fi

cd "$IOS_DIR"
bundle exec fastlane ios upload_testflight changelog:"$CHANGELOG"
