## Cursor Cloud specific instructions

### 환경 준비 (Cloud Agent 공통)
- `scripts/run_quality_checks.sh`는 Flutter SDK가 없으면 자동으로 `scripts/setup_flutter_env.sh`를 실행합니다.
- 스크립트 내부에서 기본 `FLUTTER_HOME`을 `$HOME/.local/flutter`로 사용하고, `PATH`를 즉시 반영합니다.
- `PUB_CACHE`는 기본으로 `$HOME/.pub-cache`를 사용합니다. 이미 존재하면 재사용하고, 없으면 자동 생성됩니다.

### 기본 검증 흐름
- 빠른 품질 확인은 아래 1개 명령으로 수행합니다.
  - `bash scripts/run_quality_checks.sh`
- 실행 내용:
  1) `flutter --version`
  2) `flutter pub get`
  3) `flutter analyze`
  4) 핵심 테스트 3종

### 설명 방식 (초급 개발자 대상)
- 앞으로 코드 변경/업데이트 설명은 한국어로 작성합니다.
- 설명 시 아래 3가지를 짧게 포함합니다.
  1) **왜 바꿨는지** (문제/목적)
  2) **무엇을 바꿨는지** (파일/동작)
  3) **어떻게 확인하는지** (실행 명령/기대 결과)
