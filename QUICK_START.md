# KOMEET 빠른 시작 가이드

## 1. Firebase 프로젝트 생성 및 설정

### 1.1 Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `komeet-dating` (또는 원하는 이름)
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

### 1.2 FlutterFire CLI로 자동 설정

가장 간단한 방법입니다:

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 디렉토리로 이동
cd jp-kr-dating-app/komeet/mobile

# Firebase 프로젝트 연결
flutterfire configure
```

이 명령어는:
- Firebase 프로젝트 선택
- 플랫폼 선택 (Android, iOS, Web)
- 필요한 설정 파일 자동 생성
- `lib/firebase_options.dart` 자동 생성

### 1.3 수동 설정 (선택사항)

자세한 내용은 `FIREBASE_SETUP.md` 파일을 참고하세요.

## 2. Firebase 서비스 활성화

### 2.1 Authentication (인증)

1. Firebase Console → Authentication
2. "시작하기" 클릭
3. "이메일/비밀번호" 활성화
4. "익명" 인증 활성화

### 2.2 Cloud Firestore (데이터베이스)

1. Firebase Console → Firestore Database
2. "데이터베이스 만들기" 클릭
3. 프로덕션 모드 선택
4. 위치: `asia-northeast1` (도쿄) 또는 원하는 위치
5. 데이터베이스 생성

**보안 규칙 설정:**

Firebase Console → Firestore Database → 규칙 탭에서 다음 규칙 적용:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **주의**: 위 규칙은 개발용입니다. 프로덕션에서는 더 엄격한 규칙이 필요합니다. (`FIREBASE_SETUP.md` 참고)

### 2.3 Firebase Storage (파일 저장)

1. Firebase Console → Storage
2. "시작하기" 클릭
3. 위치 선택 (Firestore와 동일 권장)

**보안 규칙 설정:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **주의**: 위 규칙은 개발용입니다. 프로덕션에서는 더 엄격한 규칙이 필요합니다.

## 3. 앱 실행

### 3.1 의존성 설치

```bash
cd jp-kr-dating-app/komeet/mobile
flutter pub get
```

### 3.2 앱 실행

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

## 4. 테스트

### 4.1 로그인 테스트

1. 앱 실행
2. "익명으로 시작하기" 클릭
3. 로그인 성공 확인

### 4.2 프로필 생성 테스트

1. 프로필 페이지에서 "프로필 작성하기" 클릭
2. 프로필 정보 입력
3. 사진 업로드 (선택사항)
4. 저장

### 4.3 Firestore 데이터 확인

1. Firebase Console → Firestore Database
2. `profiles` 컬렉션에서 프로필 데이터 확인
3. `users` 컬렉션에서 FCM 토큰 확인

## 5. 문제 해결

### 5.1 Firebase 초기화 오류

- `flutterfire configure` 명령어 재실행
- `lib/firebase_options.dart` 파일 확인
- Android: `android/app/google-services.json` 확인
- iOS: `ios/Runner/GoogleService-Info.plist` 확인

### 5.2 빌드 오류

**Android:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**iOS:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### 5.3 의존성 충돌

```bash
flutter pub upgrade
flutter pub get
```

## 6. 다음 단계

1. ✅ Firebase 프로젝트 설정 완료
2. ✅ 기본 기능 테스트 완료
3. 다음 작업:
   - Cloud Functions 설정 (푸시 알림 자동 전송)
   - 보안 규칙 세부 설정
   - 프로덕션 배포 준비

## 도움말

- 자세한 설정: `FIREBASE_SETUP.md` 참고
- Firebase 문서: https://firebase.google.com/docs
- FlutterFire 문서: https://firebase.flutter.dev/

