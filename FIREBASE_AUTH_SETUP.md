# Firebase Authentication 설정 가이드

## 문제 해결: 로그인/회원가입이 작동하지 않는 경우

앱에서 회원가입, 구글 로그인, 카카오/네이버 로그인이 작동하지 않는다면 Firebase Console에서 다음 설정을 확인하세요.

## 1. Firebase Authentication 활성화

### 1.1 Firebase Console 접속
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (komeet-6caca)

### 1.2 Authentication 활성화
1. 왼쪽 메뉴에서 **"Authentication"** 클릭
2. "시작하기" 버튼 클릭 (처음 사용하는 경우)

### 1.3 이메일/비밀번호 인증 활성화
1. Authentication 페이지에서 **"Sign-in method"** 탭 클릭
2. **"이메일/비밀번호"** 클릭
3. **"사용 설정"** 토글을 **ON**으로 변경
4. **"저장"** 클릭

## 2. Google Sign-In 활성화

### 2.1 Google 제공자 설정
1. Authentication → Sign-in method 페이지에서
2. **"Google"** 클릭
3. **"사용 설정"** 토글을 **ON**으로 변경
4. **프로젝트 지원 이메일** 선택 (기본값 사용 가능)
5. **"저장"** 클릭

### 2.2 SHA-1 인증서 지문 추가 (Android)
Google Sign-In이 작동하려면 Android 앱의 SHA-1 인증서 지문을 Firebase에 등록해야 합니다.

#### 디버그 키스토어 SHA-1 확인:
```bash
cd android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### 릴리즈 키스토어 SHA-1 확인:
```bash
cd android\app
keytool -list -v -keystore komeet-release-key.jks -alias komeet -storepass komeet123456
```

#### Firebase Console에 추가:
1. Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱 선택
2. "SHA 인증서 지문" 섹션에서 **"지문 추가"** 클릭
3. 위 명령어로 확인한 SHA-1 값을 입력
4. 저장

## 3. 카카오/네이버 로그인 (현재 미지원)

**중요:** Firebase는 카카오와 네이버를 직접 지원하지 않습니다.

현재 코드에서는 커스텀 OAuth 제공자를 사용하려고 하지만, Firebase Console에서 설정이 필요합니다.

### 임시 해결책:
1. **카카오/네이버 로그인 버튼을 숨기거나 비활성화** (권장)
2. 또는 Firebase Console에서 커스텀 OAuth 제공자 설정 (복잡함)

### 커스텀 OAuth 제공자 설정 (고급):
1. Firebase Console → Authentication → Sign-in method
2. "Add new provider" → "Custom" 선택
3. Provider ID: `oidc.kakao` 또는 `oidc.naver`
4. 카카오/네이버 개발자 콘솔에서 OAuth 설정 필요

## 4. 약관 페이지 확인

약관 페이지는 정상적으로 구현되어 있습니다. 클릭 시 페이지가 열리지 않는다면:

1. 라우팅이 제대로 작동하는지 확인
2. 앱을 재시작해보세요
3. 에러 로그 확인

## 5. 테스트 체크리스트

### ✅ 확인 사항:
- [ ] Firebase Console에서 Authentication 활성화됨
- [ ] 이메일/비밀번호 인증 활성화됨
- [ ] Google Sign-In 활성화됨
- [ ] SHA-1 인증서 지문이 Firebase에 등록됨
- [ ] `google-services.json` 파일이 `android/app/` 폴더에 있음
- [ ] 앱을 재빌드하고 재설치함

### 테스트 순서:
1. **이메일/비밀번호 회원가입** 테스트
2. **이메일/비밀번호 로그인** 테스트
3. **Google 로그인** 테스트
4. **약관 페이지** 클릭 테스트

## 6. 문제 해결

### 회원가입이 안 되는 경우:
- Firebase Console에서 "이메일/비밀번호" 인증이 활성화되어 있는지 확인
- 에러 메시지 확인 (앱에서 빨간색 스낵바로 표시됨)

### Google 로그인이 안 되는 경우:
- Firebase Console에서 "Google" 인증이 활성화되어 있는지 확인
- SHA-1 인증서 지문이 등록되어 있는지 확인
- `google-services.json` 파일이 최신인지 확인

### 카카오/네이버 로그인이 안 되는 경우:
- 현재 Firebase에서 직접 지원하지 않음
- 임시로 버튼을 숨기거나, 커스텀 OAuth 제공자 설정 필요

## 7. 빠른 설정 스크립트

Firebase 설정을 확인하는 스크립트:

```bash
# SHA-1 확인 (디버그)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1"

# SHA-1 확인 (릴리즈)
keytool -list -v -keystore android\app\komeet-release-key.jks -alias komeet -storepass komeet123456 | findstr "SHA1"
```

SHA-1 값을 복사하여 Firebase Console에 등록하세요.


