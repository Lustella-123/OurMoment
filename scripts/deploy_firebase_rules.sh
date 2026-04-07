#!/usr/bin/env bash
set -euo pipefail

# Firestore/Storage 규칙 + 인덱스 배포
# 사용 예)
#   scripts/deploy_firebase_rules.sh
#   FIREBASE_PROJECT_ID=my-project scripts/deploy_firebase_rules.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "[deploy_firebase_rules] firebase CLI가 없습니다."
  echo "  npm i -g firebase-tools"
  exit 1
fi

PROJECT_OPT=()
if [[ -n "${FIREBASE_PROJECT_ID:-}" ]]; then
  PROJECT_OPT=(--project "$FIREBASE_PROJECT_ID")
fi

echo "[deploy_firebase_rules] Firestore rules 배포"
firebase deploy "${PROJECT_OPT[@]}" --only firestore:rules

echo "[deploy_firebase_rules] Firestore indexes 배포"
firebase deploy "${PROJECT_OPT[@]}" --only firestore:indexes

echo "[deploy_firebase_rules] Storage rules 배포"
firebase deploy "${PROJECT_OPT[@]}" --only storage

echo "[deploy_firebase_rules] 완료"
