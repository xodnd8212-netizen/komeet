# 카카오/네이버 로그인 설정 가이드

## 1. 카카오 로그인 설정

### 1.1 카카오 개발자 콘솔 설정

1. [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
2. 내 애플리케이션 → 애플리케이션 추가하기
3. 앱 이름 입력 후 저장
4. 앱 키 확인 (REST API 키, 네이티브 앱 키)

### 1.2 플랫폼 설정

#### Android 플랫폼 추가:
1. 플랫폼 → Android 플랫폼 등록
2. 패키지 이름 입력: `com.komeet`
3. 키 해시 등록:
   ```bash
   # 디버그 키 해시
   keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64
   
   # 릴리즈 키 해시
   keytool -exportcert -alias komeet -keystore android\app\komeet-release-key.jks -storepass komeet123456 | openssl sha1 -binary | openssl base64
   ```
4. 저장

#### iOS 플랫폼 추가 (선택사항):
1. 플랫폼 → iOS 플랫폼 등록
2. 번들 ID 입력
3. 저장

### 1.3 카카오 로그인 활성화

1. 제품 설정 → 카카오 로그인 → 활성화 설정 ON
2. Redirect URI 등록:
   - Android: `kakao{YOUR_NATIVE_APP_KEY}://oauth`
   - iOS: `kakao{YOUR_NATIVE_APP_KEY}://oauth`
3. 동의 항목 설정 (이메일, 닉네임 등)
4. 저장

### 1.4 앱에 네이티브 앱 키 설정

`lib/main.dart` 파일에서 카카오 네이티브 앱 키를 설정하세요:

```dart
kakao.KakaoSdk.init(
  nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY', // 여기에 실제 키 입력
);
```

## 2. 네이버 로그인 설정

### 2.1 네이버 개발자 센터 설정

1. [네이버 개발자 센터](https://developers.naver.com/) 접속
2. 애플리케이션 → 애플리케이션 등록
3. 애플리케이션 이름 입력
4. 사용 API: 네이버 로그인 선택
5. 로그인 오픈 API 서비스 환경: 모바일 앱 선택
6. Android 패키지 이름: `com.komeet`
7. Android 앱 서명키: SHA-256 해시 입력
   ```bash
   keytool -list -v -keystore android\app\komeet-release-key.jks -alias komeet -storepass komeet123456 | findstr "SHA256"
   ```
8. 저장 후 Client ID와 Client Secret 확인

### 2.2 Android 설정

`android/app/build.gradle.kts` 파일에 네이버 Client ID 추가:

```kotlin
defaultConfig {
    // ... 기존 설정 ...
    manifestPlaceholders["naverClientId"] = "YOUR_NAVER_CLIENT_ID"
    manifestPlaceholders["naverClientSecret"] = "YOUR_NAVER_CLIENT_SECRET"
    manifestPlaceholders["naverClientName"] = "KOMEET"
}
```

### 2.3 AndroidManifest.xml 설정

`android/app/src/main/AndroidManifest.xml`에 다음 추가:

```xml
<activity
    android:name="com.navercorp.nid.oauth.view.NidOAuthLoginActivity"
    android:exported="true"
    android:screenOrientation="portrait"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

## 3. 테스트

### 3.1 카카오 로그인 테스트

1. 앱 실행
2. "카카오톡으로 계속하기" 버튼 클릭
3. 카카오톡 앱이 설치되어 있으면 카카오톡으로 로그인
4. 없으면 카카오계정으로 로그인

### 3.2 네이버 로그인 테스트

1. 앱 실행
2. "네이버로 계속하기" 버튼 클릭
3. 네이버 로그인 화면에서 로그인

## 4. 문제 해결

### 카카오 로그인이 안 되는 경우:
- 카카오 개발자 콘솔에서 네이티브 앱 키가 올바른지 확인
- 키 해시가 올바르게 등록되었는지 확인
- `lib/main.dart`에서 네이티브 앱 키가 올바르게 설정되었는지 확인

### 네이버 로그인이 안 되는 경우:
- 네이버 개발자 센터에서 Client ID가 올바른지 확인
- Android 패키지 이름이 올바르게 등록되었는지 확인
- SHA-256 해시가 올바르게 등록되었는지 확인
- `build.gradle.kts`에 manifestPlaceholders가 올바르게 설정되었는지 확인

## 5. 주의사항

- 카카오/네이버 로그인은 각각의 개발자 콘솔에서 앱을 등록해야 합니다
- 프로덕션 배포 전에 실제 키로 교체해야 합니다
- 키 해시는 디버그와 릴리즈 모두 등록하는 것을 권장합니다


