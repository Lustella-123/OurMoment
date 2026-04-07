#!/usr/bin/env bash
# iOS 시뮬레이터에서 flutter run 후, 첫 프롬프트에서 핫 리로드(r) 1회 자동 전송
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVICE_ID="${1:-}"

pick_first_ios_simulator() {
  flutter devices --machine 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for d in data:
    if not d.get('supported', True):
        continue
    pid = (d.get('targetPlatform') or '').lower()
    if 'ios' in pid and d.get('emulator'):
        print(d.get('id', ''))
        raise SystemExit(0)
print('')
" 2>/dev/null || true
}

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(pick_first_ios_simulator)"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "iOS 시뮬레이터를 찾지 못했습니다."
  echo "  open -a Simulator"
  echo "  또는: $0 <기기ID>   (예: flutter devices 로 ID 확인)"
  exit 1
fi

echo "기기: $DEVICE_ID"

if ! command -v expect >/dev/null 2>&1; then
  echo "expect가 없습니다. 설치: brew install expect"
  echo "대신 수동 실행:"
  echo "  cd \"$ROOT\" && flutter run -d \"$DEVICE_ID\""
  echo "  뜬 뒤 터미널에서 r 입력"
  exit 1
fi

export PROJECT_ROOT="$ROOT"
exec expect "$ROOT/scripts/flutter_run_hot.expect" "$DEVICE_ID"
