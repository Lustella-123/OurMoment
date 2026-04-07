#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.local/flutter}"
AUTO_INSTALL_SYSTEM_DEPS="${AUTO_INSTALL_SYSTEM_DEPS:-false}"
UPDATE_FLUTTER="${UPDATE_FLUTTER:-false}"
RUN_FLUTTER_DOCTOR="${RUN_FLUTTER_DOCTOR:-true}"
FLUTTER_PRECACHE="${FLUTTER_PRECACHE:-false}"
PROJECT_PUB_GET="${PROJECT_PUB_GET:-true}"

log() {
  printf '[setup_flutter_env] %s\n' "$*"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_system_deps_linux() {
  local -a deps=(curl git unzip xz-utils zip libglu1-mesa)
  if ! have_cmd sudo; then
    log "sudo가 없어 시스템 패키지 자동 설치를 건너뜁니다."
    return 1
  fi
  log "시스템 패키지 설치: ${deps[*]}"
  sudo apt-get update -y
  sudo apt-get install -y "${deps[@]}"
}

ensure_system_deps() {
  local -a required=(curl git unzip xz)
  local -a missing=()
  local cmd
  for cmd in "${required[@]}"; do
    if ! have_cmd "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  log "누락된 시스템 명령어: ${missing[*]}"
  if [[ "$AUTO_INSTALL_SYSTEM_DEPS" == "true" ]]; then
    if [[ "${OSTYPE:-}" == linux* ]]; then
      install_system_deps_linux || true
    else
      log "Linux 외 OS 자동 설치는 지원하지 않습니다. 수동 설치해 주세요."
    fi
  fi

  local still_missing=()
  for cmd in "${missing[@]}"; do
    if ! have_cmd "$cmd"; then
      still_missing+=("$cmd")
    fi
  done
  if [[ "${#still_missing[@]}" -gt 0 ]]; then
    log "여전히 누락됨: ${still_missing[*]}"
    exit 1
  fi
}

install_or_update_flutter() {
  if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
    log "Flutter SDK 설치: $FLUTTER_HOME (channel=$FLUTTER_CHANNEL)"
    mkdir -p "$(dirname "$FLUTTER_HOME")"
    git clone --depth 1 -b "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
    return 0
  fi

  if [[ "$UPDATE_FLUTTER" == "true" ]]; then
    log "Flutter SDK 업데이트: $FLUTTER_HOME (channel=$FLUTTER_CHANNEL)"
    git -C "$FLUTTER_HOME" fetch origin "$FLUTTER_CHANNEL" --depth 1
    git -C "$FLUTTER_HOME" checkout "$FLUTTER_CHANNEL"
    git -C "$FLUTTER_HOME" reset --hard "origin/$FLUTTER_CHANNEL"
  fi
}

main() {
  ensure_system_deps
  install_or_update_flutter

  export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

  log "Flutter 버전 확인"
  flutter --version

  flutter config --no-analytics >/dev/null

  if [[ "$RUN_FLUTTER_DOCTOR" == "true" ]]; then
    log "flutter doctor 실행 (환경 점검)"
    flutter doctor -v || true
  fi

  if [[ "$FLUTTER_PRECACHE" == "true" ]]; then
    log "Flutter artifact precache 실행"
    flutter precache
  fi

  if [[ "$PROJECT_PUB_GET" == "true" ]]; then
    log "프로젝트 의존성 설치 (flutter pub get)"
    (
      cd "$ROOT_DIR"
      flutter pub get
    )
  fi

  log "완료"
  log "PATH 반영 필요 시: export PATH=\"$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:\$PATH\""
}

main "$@"
