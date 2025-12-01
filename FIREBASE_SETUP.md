# Firebase 설정 가이드

이 문서는 KOMEET 앱의 Firebase 설정 방법을 안내합니다.

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: `komeet-dating`)
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

## 2. Android 앱 설정

### 2.1 Android 앱 등록

1. Firebase Console에서 프로젝트 선택
2. 왼쪽 메뉴에서 "프로젝트 설정" 클릭
3. "내 앱" 섹션에서 Android 아이콘 클릭
4. Android 패키지 이름 입력:
   ```
   io.flutter.plugins.komeet
   ```
   (실제 패키지 이름은 `android/app/src/main/AndroidManifest.xml`에서 확인)
5. 앱 등록 완료

### 2.2 google-services.json 다운로드

1. `google-services.json` 파일 다운로드
2. 파일을 다음 위치에 복사:
   ```
   android/app/google-services.json
   ```

### 2.3 build.gradle 설정

#### 프로젝트 레벨 build.gradle (`android/build.gradle`)

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath 'com.google.gms:google-services:4.3.15'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

#### 앱 레벨 build.gradle (`android/app/build.gradle`)

파일 맨 아래에 다음 추가:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 3. iOS 앱 설정

### 3.1 iOS 앱 등록

1. Firebase Console에서 프로젝트 선택
2. "프로젝트 설정" → "내 앱" → iOS 아이콘 클릭
3. iOS 번들 ID 입력:
   ```
   io.flutter.plugins.komeet
   ```
   (실제 번들 ID는 `ios/Runner/Info.plist`에서 확인)
4. 앱 등록 완료

### 3.2 GoogleService-Info.plist 다운로드

1. `GoogleService-Info.plist` 파일 다운로드
2. Xcode에서 `ios/Runner` 폴더에 파일 추가
3. 또는 직접 파일을 다음 위치에 복사:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

### 3.3 Podfile 설정

`ios/Podfile` 파일 확인 (일반적으로 자동 설정됨)

## 4. Web 앱 설정

### 4.1 Web 앱 등록

1. Firebase Console에서 프로젝트 선택
2. "프로젝트 설정" → "내 앱" → Web 아이콘 클릭
3. 앱 닉네임 입력
4. Firebase Hosting 설정 (선택사항)
5. 앱 등록 완료

### 4.2 Firebase 설정 코드

`lib/firebase_options.dart` 파일이 자동 생성됩니다. 없으면 다음 명령어 실행:

```bash
flutter pub add firebase_core
flutterfire configure
```

## 5. Firebase 서비스 활성화

### 5.1 Authentication (인증)

1. Firebase Console → Authentication
2. "시작하기" 클릭
3. 다음 인증 방법 활성화:
   - 이메일/비밀번호
   - 익명 인증

### 5.2 Cloud Firestore (데이터베이스)

1. Firebase Console → Firestore Database
2. "데이터베이스 만들기" 클릭
3. 프로덕션 모드 선택 (나중에 테스트 모드로 변경 가능)
4. 위치 선택 (예: `asia-northeast1` - 도쿄)
5. 데이터베이스 생성 완료

**보안 규칙 설정:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 프로필: 자신의 프로필만 읽기/쓰기 가능
    match /profiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 좋아요: 인증된 사용자만 읽기/쓰기 가능
    match /likes/{likeId} {
      allow read, write: if request.auth != null;
    }
    
    // 매칭: 참여자만 읽기 가능
    match /matches/{matchId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      allow write: if request.auth != null;
    }
    
    // 채팅방: 참여자만 읽기/쓰기 가능
    match /chatRooms/{roomId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
    }
    
    // 메시지: 채팅방 참여자만 읽기/쓰기 가능
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // 알림: 자신의 알림만 읽기 가능
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow write: if request.auth != null;
    }
    
    // 사용자 FCM 토큰: 자신의 토큰만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

### 5.3 Firebase Storage (파일 저장)

1. Firebase Console → Storage
2. "시작하기" 클릭
3. 보안 규칙 확인 후 시작
4. 위치 선택 (Firestore와 동일한 위치 권장)

**보안 규칙 설정:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 프로필 이미지: 자신의 폴더만 업로드 가능
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 채팅 이미지: 자신의 폴더만 업로드 가능
    match /chat/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5.4 Cloud Messaging (푸시 알림)

1. Firebase Console → Cloud Messaging
2. 자동으로 활성화됨
3. Android의 경우 서버 키 확인 (나중에 Cloud Functions에서 사용)

## 6. Flutter 프로젝트 설정

### 6.1 Firebase CLI 설치

```bash
npm install -g firebase-tools
```

### 6.2 FlutterFire CLI 설치

```bash
dart pub global activate flutterfire_cli
```

### 6.3 Firebase 프로젝트 연결

```bash
cd jp-kr-dating-app/komeet/mobile
flutterfire configure
```

이 명령어는:
- Firebase 프로젝트 선택
- 플랫폼 선택 (Android, iOS, Web)
- `lib/firebase_options.dart` 파일 자동 생성

### 6.4 main.dart 업데이트

`lib/main.dart`의 Firebase 초기화 코드가 이미 설정되어 있습니다:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 7. 테스트

### 7.1 앱 실행

```bash
flutter run
```

### 7.2 확인 사항

1. 로그인 화면이 정상적으로 표시되는지 확인
2. 익명 로그인 테스트
3. 프로필 생성 테스트
4. Firestore에 데이터가 저장되는지 확인

## 8. 문제 해결

### 8.1 Android 빌드 오류

- `google-services.json` 파일이 올바른 위치에 있는지 확인
- `build.gradle` 파일에 플러그인이 추가되었는지 확인

### 8.2 iOS 빌드 오류

- `GoogleService-Info.plist` 파일이 Xcode 프로젝트에 추가되었는지 확인
- `pod install` 실행:
  ```bash
  cd ios
  pod install
  cd ..
  ```

### 8.3 Firebase 초기화 오류

- Firebase 설정 파일이 올바른 위치에 있는지 확인
- `flutterfire configure` 명령어 재실행

## 9. 다음 단계

1. Cloud Functions 설정 (푸시 알림 자동 전송)
2. Firebase Analytics 설정
3. Crashlytics 설정 (에러 추적)

## 참고 자료

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Firebase 보안 규칙 가이드](https://firebase.google.com/docs/firestore/security/get-started)

