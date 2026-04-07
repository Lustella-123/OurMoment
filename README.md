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

## 최신 반영 요약 (한국어)

가장 최신 작업 브랜치의 변경을 기준 브랜치에 반영했습니다. 이번 정리의 핵심은 아래와 같습니다.

- 인증 전환/세션 처리 안정성 개선 및 관련 테스트 추가
- 캘린더/피드/메모/프로필 화면의 안정화 및 UX 보정
- Firestore 규칙 보강과 커플/캘린더 저장소 로직 보완
- 테마/위젯 정리와 로컬라이제이션 문자열 확장
- Cursor Cloud에서 바로 재현 가능한 셋업/품질검사 스크립트 추가
