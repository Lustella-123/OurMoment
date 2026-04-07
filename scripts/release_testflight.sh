#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT/ios"
CHANGELOG="${1:-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERROR] TestFlight upload is supported only on macOS."
  exit 1
fi

if [[ -z "$CHANGELOG" ]]; then
  echo "Usage: bash scripts/release_testflight.sh \"release notes\""
  exit 1
fi

if [[ ! -d "$IOS_DIR" ]]; then
  echo "[ERROR] Could not find ios directory: $IOS_DIR"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ERROR] flutter command not found."
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "[ERROR] bundler(bundle) command not found. Run setup script first."
  exit 1
fi

cd "$IOS_DIR"

if [[ ! -f "fastlane/.env" ]]; then
  echo "[ERROR] Missing ios/fastlane/.env file."
  echo "Run first: bash scripts/setup_testflight_fastlane.sh"
  exit 1
fi

if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "fastlane/.env"
  set +a
fi

if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  echo "[ERROR] APP_STORE_CONNECT_API_KEY_PATH is not set."
  exit 1
fi

if [[ ! -f "${APP_STORE_CONNECT_API_KEY_PATH}" ]]; then
  echo "[ERROR] API key file not found: ${APP_STORE_CONNECT_API_KEY_PATH}"
  exit 1
fi

echo "[1/2] Run Fastlane TestFlight upload"
bundle exec fastlane ios upload_testflight changelog:"$CHANGELOG"

echo "[2/2] Done"
echo "Check build processing status in App Store Connect."
