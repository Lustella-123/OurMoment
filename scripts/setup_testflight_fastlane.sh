#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT/ios"

if [[ ! -d "$IOS_DIR" ]]; then
  echo "[ERROR] Could not find ios directory: $IOS_DIR"
  exit 1
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "[ERROR] ruby is not installed. Recommended: rbenv + ruby 3.x"
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "[INFO] bundler not found. Installing..."
  gem install bundler
fi

cd "$IOS_DIR"

if command -v flutter >/dev/null 2>&1; then
  echo "[CHECK] flutter doctor (summary)"
  flutter doctor -v || true
else
  echo "[WARN] flutter command not found. Check your PATH."
fi

echo "[1/3] bundle install"
bundle install

echo "[2/3] Validate fastlane env template"
if [[ ! -f "fastlane/.env.default" ]]; then
  echo "[ERROR] Missing fastlane/.env.default"
  exit 1
fi

if [[ ! -f "fastlane/.env" ]]; then
  cp "fastlane/.env.default" "fastlane/.env"
  echo "[DONE] Created fastlane/.env. Fill in required values."
else
  echo "[DONE] Keeping existing fastlane/.env."
fi

echo "[3/3] Setup complete"
echo "Next steps:"
echo "  1) Fill ios/fastlane/.env"
echo "  2) Verify APP_STORE_CONNECT_API_KEY_PATH absolute path"
echo "  3) bash scripts/release_testflight.sh \"Release notes\""
