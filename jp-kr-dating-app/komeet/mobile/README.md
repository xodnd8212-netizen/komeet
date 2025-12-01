# KOMEET - 일본 여성과 한국 남성을 연결하는 소개팅 앱

KOMEET은 일본 여성과 한국 남성을 연결하는 소개팅 앱입니다. Wipi, Glam 등 인기 소개팅 앱을 벤치마킹하여 제작되었습니다.

## 주요 기능

- ✅ **사용자 인증**: 이메일/비밀번호, 익명 로그인
- ✅ **프로필 관리**: 사진 업로드, 자기소개, 관심사 설정
- ✅ **매칭 시스템**: 스와이프 기반 매칭, 양방향 좋아요
- ✅ **실시간 채팅**: Firestore 기반 실시간 메시징
- ✅ **위치 기반 추천**: 거리 및 도시 필터링
- ✅ **푸시 알림**: 매칭 및 채팅 알림
- ✅ **다국어 지원**: 한국어/일본어

## 기술 스택

- **Flutter**: 크로스 플랫폼 앱 개발
- **Firebase**:
  - Authentication: 사용자 인증
  - Firestore: 실시간 데이터베이스
  - Storage: 이미지 저장
  - Cloud Messaging: 푸시 알림
- **GoRouter**: 네비게이션
- **Provider**: 상태 관리

## 빠른 시작

### 1. Firebase 프로젝트 설정

자세한 내용은 다음 파일을 참고하세요:
- **빠른 시작**: `QUICK_START.md`
- **상세 가이드**: `FIREBASE_SETUP.md`

간단한 방법:

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 디렉토리로 이동
cd jp-kr-dating-app/komeet/mobile

# Firebase 프로젝트 연결
flutterfire configure
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 프로젝트 구조

```
lib/
├── features/          # 기능별 페이지
│   ├── auth/         # 로그인/인증
│   ├── profile/      # 프로필 관리
│   ├── match/        # 매칭 화면
│   ├── chat/         # 채팅
│   └── settings/     # 설정
├── services/          # 백엔드 서비스
│   ├── auth_service.dart
│   ├── profile_service.dart
│   ├── chat_service.dart
│   ├── match_service.dart
│   └── push_notifications.dart
├── models/            # 데이터 모델
│   ├── profile.dart
│   └── chat_message.dart
├── theme/             # 테마 설정
├── i18n/              # 다국어 지원
└── main.dart          # 앱 진입점
```

## 주요 기능 상세

### 프로필 관리
- 최대 6장의 프로필 사진 업로드
- 이름, 나이, 도시, 자기소개 입력
- 관심사 선택 (최대 5개)
- 최대 거리 설정

### 매칭 시스템
- 스와이프 제스처로 좋아요/건너뛰기
- 양방향 좋아요 시 자동 매칭
- 위치 기반 추천 (거리 필터링)
- 도쿄 필터 옵션

### 실시간 채팅
- Firestore 기반 실시간 메시징
- 이미지 전송 지원
- 읽음 표시
- 채팅방 목록

### 알림 시스템
- 매칭 성공 알림
- 새 메시지 알림
- 로컬 알림 + FCM 푸시 알림

## Firebase 설정

### 필수 서비스

1. **Authentication**
   - 이메일/비밀번호 활성화
   - 익명 인증 활성화

2. **Cloud Firestore**
   - 데이터베이스 생성
   - 보안 규칙 설정 (개발용: 모든 인증 사용자 허용)

3. **Firebase Storage**
   - Storage 활성화
   - 보안 규칙 설정

4. **Cloud Messaging**
   - 자동 활성화

자세한 설정 방법은 `FIREBASE_SETUP.md`를 참고하세요.

## 개발 환경

- Flutter SDK: >=2.12.0 <3.0.0
- Dart: >=2.12.0
- Firebase: 최신 버전

## 문제 해결

### Firebase 초기화 오류
- `flutterfire configure` 재실행
- 설정 파일 위치 확인 (`google-services.json`, `GoogleService-Info.plist`)

### 빌드 오류
```bash
flutter clean
flutter pub get
```

### 의존성 충돌
```bash
flutter pub upgrade
```

## 다음 단계

- [ ] Cloud Functions 설정 (푸시 알림 자동 전송)
- [ ] 보안 규칙 세부 설정
- [ ] 프로덕션 배포 준비
- [ ] 성능 최적화
- [ ] 테스트 코드 작성

## 라이선스

MIT License

## 참고 자료

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Flutter 공식 문서](https://flutter.dev/docs)