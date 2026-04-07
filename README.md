# ourmoment

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cursor/Cloud 환경 빠른 셋업

```bash
# 1) Flutter SDK 설치 + PATH 등록(~/.bashrc)
./scripts/setup_flutter_env.sh

# 2) 프로젝트 의존성 설치(pub get)
./scripts/bootstrap_project.sh

# 3) 분석 + 테스트(기본 테스트 + 이번 이슈 관련 3개 테스트)
./scripts/run_quality_checks.sh

# 4) (선택) Firestore/Storage 규칙·인덱스 배포
./scripts/deploy_firebase_rules.sh
```
