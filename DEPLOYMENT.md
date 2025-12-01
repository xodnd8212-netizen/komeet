# 배포 가이드

이 문서는 KOMEET 앱의 배포 준비 및 배포 방법을 안내합니다.

## 1. 배포 전 체크리스트

### 1.1 코드 품질
- [ ] 모든 린터 오류 수정
- [ ] 테스트 코드 작성 및 실행
- [ ] 코드 리뷰 완료

### 1.2 Firebase 설정
- [ ] Firebase 프로젝트 생성 완료
- [ ] Firestore 보안 규칙 적용 (`firestore.rules`)
- [ ] Storage 보안 규칙 적용 (`storage.rules`)
- [ ] Authentication 활성화
- [ ] Cloud Messaging 설정 완료

### 1.3 환경 변수
- [ ] Firebase 설정 파일 확인
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
  - Web: `lib/firebase_options.dart`

### 1.4 보안
- [ ] API 키가 코드에 하드코딩되지 않았는지 확인
- [ ] 민감한 정보가 버전 관리에 포함되지 않았는지 확인
- [ ] `.gitignore` 파일 확인

## 2. Android 배포

### 2.1 빌드 설정

#### `android/app/build.gradle` 확인

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "io.flutter.plugins.komeet" // 실제 패키지 이름으로 변경
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 2.2 키스토어 생성

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2.3 키스토어 설정

`android/key.properties` 파일 생성:

```properties
storePassword=<키스토어 비밀번호>
keyPassword=<키 비밀번호>
keyAlias=upload
storeFile=<키스토어 파일 경로>
```

### 2.4 APK 빌드

```bash
flutter build apk --release
```

### 2.5 App Bundle 빌드 (Google Play Store)

```bash
flutter build appbundle --release
```

### 2.6 Google Play Console 업로드

1. [Google Play Console](https://play.google.com/console) 접속
2. 앱 생성
3. 앱 번들 업로드
4. 스토어 정보 입력
5. 심사 제출

## 3. iOS 배포

### 3.1 Xcode 설정

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Signing & Capabilities에서 팀 선택
3. Bundle Identifier 설정

### 3.2 빌드 설정

`ios/Runner/Info.plist` 확인:

```xml
<key>CFBundleVersion</key>
<string>1.0.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### 3.3 Archive 생성

1. Xcode에서 Product → Archive
2. Archive 완료 후 Distribute App
3. App Store Connect 선택
4. 업로드

### 3.4 App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. 앱 생성
3. 앱 정보 입력
4. 심사 제출

## 4. Web 배포

### 4.1 빌드

```bash
flutter build web --release
```

### 4.2 Firebase Hosting 배포

```bash
# Firebase CLI 설치 (이미 했다면 생략)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 초기화
firebase init hosting

# 배포
firebase deploy --only hosting
```

### 4.3 다른 호스팅 서비스

빌드된 파일은 `build/web/` 디렉토리에 있습니다. 이를 원하는 호스팅 서비스에 업로드하세요.

## 5. Windows 배포

### 5.1 빌드

```bash
flutter build windows --release
```

### 5.2 패키징

빌드된 파일은 `build/windows/runner/Release/` 디렉토리에 있습니다.

## 6. 환경별 설정

### 6.1 개발 환경

- Firebase 프로젝트: 개발용 프로젝트 사용
- 디버그 모드 활성화
- 로그 출력 활성화

### 6.2 프로덕션 환경

- Firebase 프로젝트: 프로덕션 프로젝트 사용
- 릴리즈 모드 빌드
- 로그 최소화
- 에러 추적 활성화 (Sentry 등)

## 7. 버전 관리

### 7.1 버전 번호 형식

`pubspec.yaml`에서 버전 관리:

```yaml
version: 1.0.0+1
# 형식: major.minor.patch+build
```

### 7.2 버전 업데이트 규칙

- **Major**: 큰 기능 변경, 하위 호환성 깨짐
- **Minor**: 새로운 기능 추가, 하위 호환성 유지
- **Patch**: 버그 수정
- **Build**: 빌드 번호 (자동 증가)

## 8. 모니터링 및 분석

### 8.1 Firebase Analytics

Firebase Console에서 앱 사용량 모니터링

### 8.2 Crashlytics

에러 추적 및 크래시 리포트 확인

### 8.3 Performance Monitoring

앱 성능 모니터링

## 9. 업데이트 배포

### 9.1 버전 업데이트

1. `pubspec.yaml`에서 버전 번호 증가
2. 변경 사항 문서화
3. 빌드 및 테스트
4. 배포

### 9.2 강제 업데이트 (선택사항)

Firebase Remote Config를 사용하여 최소 버전 요구사항 설정

## 10. 문제 해결

### 10.1 빌드 오류

```bash
flutter clean
flutter pub get
flutter build <platform> --release
```

### 10.2 서명 오류

- 키스토어 파일 경로 확인
- 비밀번호 확인
- 키 별칭 확인

### 10.3 Firebase 연결 오류

- 설정 파일 위치 확인
- Firebase 프로젝트 ID 확인
- 인터넷 연결 확인

## 참고 자료

- [Flutter 배포 가이드](https://flutter.dev/docs/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)

