# KOMEET - 일본 여성과 한국 남성을 연결하는 소개팅 앱

KOMEET은 일본 여성과 한국 남성을 연결하는 소개팅 앱입니다. Wipi, Glam 등 인기 소개팅 앱을 벤치마킹하여 제작되었습니다.

## 🚀 빠른 시작

### 필수 요구사항
- Flutter SDK (최신 버전)
- Firebase 프로젝트 설정 완료
- Android Studio 또는 VS Code

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd komeet
```

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. Firebase 설정
자세한 내용은 `FIREBASE_SETUP.md`와 `FIREBASE_AUTH_SETUP.md`를 참고하세요.

**필수 설정:**
1. Firebase Console에서 프로젝트 생성
2. Authentication 활성화:
   - 이메일/비밀번호 인증 활성화
   - Google 로그인 활성화
3. Firestore Database 생성
4. `google-services.json` 파일을 `android/app/` 폴더에 추가

### 4. 앱 실행
```bash
# Android
flutter run

# 특정 디바이스
flutter run -d <device-id>
```

## 📱 현재 구현된 기능

### ✅ 인증 시스템
- 이메일/비밀번호 회원가입 및 로그인
- Google 로그인
- 로그인 성공 시 Firebase에 사용자 정보 자동 저장

### ✅ 프로필 관리
- 프로필 생성 및 편집
- 최대 6장의 프로필 사진 업로드
- 이름, 나이, 도시, 자기소개 입력
- 관심사 선택 (최대 5개)
- 위치 기반 추천

### ✅ 매칭 시스템
- 스와이프 제스처 (좋아요/건너뛰기)
- 양방향 좋아요 시 자동 매칭
- 위치 기반 추천 알고리즘

### ✅ 실시간 채팅
- Firestore 기반 실시간 메시징
- 텍스트 메시지 전송
- 이미지 전송
- 읽음 표시

### ✅ 알림 시스템
- 로컬 알림
- FCM 푸시 알림 구조
- 매칭 알림
- 채팅 알림

## 🧪 테스트 가이드

### 로그인 테스트
1. 앱 실행
2. 이메일/비밀번호로 회원가입 또는 Google 로그인
3. Firebase Console → Firestore → `users` 컬렉션에서 데이터 확인

자세한 테스트 방법은 `TESTING_GUIDE.md`를 참고하세요.

## 📚 주요 문서

- **`FIREBASE_SETUP.md`**: Firebase 프로젝트 설정 가이드
- **`FIREBASE_AUTH_SETUP.md`**: Firebase Authentication 설정 및 문제 해결
- **`TESTING_GUIDE.md`**: 테스트 가이드
- **`AUTH_SETUP_COMPLETE.md`**: 인증 설정 완료 가이드
- **`QUICK_START.md`**: 빠른 시작 가이드
- **`DEPLOYMENT.md`**: 배포 가이드

## 🔧 개발 환경 설정

### Android 릴리즈 빌드 설정
```bash
cd android
# 키스토어 생성 (한 번만)
create_keystore.bat

# key.properties 파일 생성
# android/key.properties 파일을 생성하고 비밀번호 입력
```

자세한 내용은 `android/SETUP_GUIDE.md`를 참고하세요.

## 📦 프로젝트 구조

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
│   └── match_service.dart
├── models/            # 데이터 모델
├── widgets/           # 재사용 가능한 위젯
└── theme/             # 테마 설정
```

## 🔐 보안

- 키스토어 파일(`*.jks`)과 `key.properties`는 Git에 커밋되지 않습니다
- Firebase 보안 규칙은 `firestore.rules`와 `storage.rules`에 정의되어 있습니다

## 🐛 문제 해결

### 로그인이 안 되는 경우
- `FIREBASE_AUTH_SETUP.md` 참고
- Firebase Console에서 Authentication 활성화 확인

### 빌드 오류
- `flutter clean` 실행 후 다시 빌드
- `flutter pub get` 실행

## 📝 라이선스

이 프로젝트는 비공개 프로젝트입니다.

## 👥 개발자 정보

- 프로젝트: KOMEET
- Firebase UID 예시: `jusLNuXpKqeqmPPEKWNoimSUPUy2`

## 🔗 관련 링크

- [Firebase Console](https://console.firebase.google.com/)
- [Flutter 공식 문서](https://docs.flutter.dev/)
