# 테스트 가이드

## 테스트 실행 방법

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/services/profile_service_test.dart

# 커버리지 포함 실행
flutter test --coverage

# 커버리지 리포트 보기
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 테스트 구조

```
test/
├── services/          # 서비스 레이어 테스트
│   ├── profile_service_test.dart
│   ├── match_service_test.dart
│   ├── auth_service_test.dart
│   └── chat_service_test.dart
├── utils/             # 유틸리티 테스트
│   └── sanitizer_test.dart
├── widgets/           # 위젯 테스트
│   └── cached_image_test.dart
└── integration/       # 통합 테스트
    └── match_flow_test.dart
```

## 테스트 커버리지 목표

- 단위 테스트: 90% 이상
- 위젯 테스트: 80% 이상
- 통합 테스트: 주요 플로우 100%

## 테스트 작성 가이드

1. **Given-When-Then 패턴 사용**
2. **명확한 테스트 이름 작성**
3. **각 테스트는 독립적으로 실행 가능**
4. **Mock 사용 최소화 (실제 서비스 사용)**

