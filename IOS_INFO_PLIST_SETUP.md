# iOS Info.plist 설정 가이드

## 현재 등록된 값

현재 `ios/Runner/Info.plist` 파일에 등록된 주요 값:

### 기본 앱 정보
- **CFBundleDisplayName**: `Komeet`
- **CFBundleName**: `komeet`
- **CFBundleIdentifier**: `$(PRODUCT_BUNDLE_IDENTIFIER)` (실제 값은 Xcode 프로젝트 설정에서 확인)
- **CFBundleVersion**: `$(FLUTTER_BUILD_NUMBER)`
- **CFBundleShortVersionString**: `$(FLUTTER_BUILD_NAME)`

### 화면 설정
- **UISupportedInterfaceOrientations**: Portrait, LandscapeLeft, LandscapeRight
- **UISupportedInterfaceOrientations~ipad**: Portrait, PortraitUpsideDown, LandscapeLeft, LandscapeRight

## 카카오/네이버 로그인을 위해 추가된 값

### 1. URL Schemes (CFBundleURLTypes)

카카오/네이버 로그인 후 앱으로 돌아오기 위한 URL Scheme 설정:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakaoYOUR_NATIVE_APP_KEY</string>
            <string>naverlogin</string>
        </array>
    </dict>
</array>
```

**설정 방법:**
- `kakaoYOUR_NATIVE_APP_KEY`를 실제 카카오 네이티브 앱 키로 교체하세요
- 예: 카카오 네이티브 앱 키가 `1234567890abcdef`라면 `kakao1234567890abcdef`로 설정

### 2. LSApplicationQueriesSchemes

다른 앱(카카오톡, 네이버)을 호출하기 위한 설정:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
    <string>kakaotalk</string>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
```

**설명:**
- `kakaokompassauth`: 카카오 인증
- `kakaolink`: 카카오 링크
- `kakaotalk`: 카카오톡 앱 호출
- `naversearchapp`: 네이버 앱 호출
- `naversearchthirdlogin`: 네이버 로그인

## 설정 완료 체크리스트

### 카카오 로그인:
- [ ] 카카오 개발자 콘솔에서 iOS 플랫폼 등록 완료
- [ ] 카카오 네이티브 앱 키 확인
- [ ] `CFBundleURLSchemes`에 `kakao{YOUR_NATIVE_APP_KEY}` 추가
- [ ] `LSApplicationQueriesSchemes`에 카카오 관련 스킴 추가
- [ ] `lib/main.dart`에서 카카오 SDK 초기화 시 네이티브 앱 키 설정

### 네이버 로그인:
- [ ] 네이버 개발자 센터에서 iOS 앱 등록 완료
- [ ] `CFBundleURLSchemes`에 `naverlogin` 추가
- [ ] `LSApplicationQueriesSchemes`에 네이버 관련 스킴 추가

## 실제 설정 예시

카카오 네이티브 앱 키가 `a1b2c3d4e5f6g7h8i9j0`인 경우:

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>kakaoa1b2c3d4e5f6g7h8i9j0</string>
    <string>naverlogin</string>
</array>
```

## 주의사항

1. **카카오 네이티브 앱 키**: 카카오 개발자 콘솔에서 발급받은 실제 키를 사용해야 합니다
2. **URL Scheme 형식**: `kakao` + 네이티브 앱 키 (공백 없이 연결)
3. **네이버 URL Scheme**: 항상 `naverlogin`으로 고정
4. **Xcode에서 확인**: Xcode 프로젝트를 열어서 Info 탭에서도 URL Types가 올바르게 설정되었는지 확인하세요

## Xcode에서 확인하는 방법

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. 프로젝트 네비게이터에서 `Runner` 선택
3. `TARGETS` → `Runner` 선택
4. `Info` 탭 클릭
5. `URL Types` 섹션에서 URL Schemes 확인

## 문제 해결

### 카카오 로그인이 안 되는 경우:
- URL Scheme이 올바르게 설정되었는지 확인 (`kakao` + 네이티브 앱 키)
- 카카오 개발자 콘솔에서 iOS 플랫폼이 등록되었는지 확인
- `LSApplicationQueriesSchemes`에 카카오 관련 스킴이 추가되었는지 확인

### 네이버 로그인이 안 되는 경우:
- URL Scheme에 `naverlogin`이 추가되었는지 확인
- 네이버 개발자 센터에서 iOS 앱이 등록되었는지 확인
- `LSApplicationQueriesSchemes`에 네이버 관련 스킴이 추가되었는지 확인
