# 인증 설정 완료 가이드

## ✅ 완료된 작업

### 1. 로그인 방법 정리
- ✅ 이메일/비밀번호 회원가입 및 로그인
- ✅ Google 로그인
- ❌ 카카오 로그인 제거
- ❌ 네이버 로그인 제거
- ❌ Apple 로그인 제거

### 2. Firebase 연동
- ✅ 로그인 성공 시 자동으로 Firebase Firestore `users` 컬렉션에 사용자 정보 저장
- ✅ 저장되는 데이터:
  - `uid`: 사용자 고유 ID
  - `email`: 이메일 주소
  - `displayName`: 표시 이름
  - `photoURL`: 프로필 사진 URL
  - `createdAt`: 계정 생성 시간
  - `updatedAt`: 마지막 업데이트 시간
  - `lastLoginAt`: 마지막 로그인 시간

### 3. 코드 정리
- ✅ 불필요한 패키지 제거 (kakao_flutter_sdk, flutter_naver_login, sign_in_with_apple)
- ✅ 사용하지 않는 코드 제거
- ✅ 린터 경고 수정

## 📋 Firebase 설정 확인

### 1. Firebase Console 설정
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (komeet-6caca)
3. **Authentication** → **Sign-in method** 확인:
   - ✅ 이메일/비밀번호: 활성화
   - ✅ Google: 활성화

### 2. Firestore 데이터 확인
로그인 후 Firebase Console → Firestore Database에서 확인:
- 컬렉션: `users`
- 문서 ID: 사용자 UID (예: `jusLNuXpKqeqmPPEKWNoimSUPUy2`)

## 🧪 테스트 방법

### 1. 이메일/비밀번호 회원가입 테스트
1. 앱 실행
2. 이메일과 비밀번호 입력 (비밀번호 6자 이상)
3. "회원가입" 버튼 클릭
4. Firebase Console에서 `users` 컬렉션 확인

### 2. 이메일/비밀번호 로그인 테스트
1. 회원가입한 이메일과 비밀번호로 로그인
2. Firebase Console에서 `lastLoginAt` 필드 업데이트 확인

### 3. Google 로그인 테스트
1. "Google 계정으로 계속하기" 버튼 클릭
2. Google 계정 선택
3. Firebase Console에서 `users` 컬렉션 확인

### 4. 특정 UID 확인
UID `jusLNuXpKqeqmPPEKWNoimSUPUy2`의 사용자 데이터 확인:
```bash
# Firebase Console에서 확인하거나
# 또는 코드에서:
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc('jusLNuXpKqeqmPPEKWNoimSUPUy2')
    .get();
```

## 📝 저장되는 데이터 구조

```json
{
  "uid": "jusLNuXpKqeqmPPEKWNoimSUPUy2",
  "email": "user@example.com",
  "displayName": "사용자 이름",
  "photoURL": "https://...",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z"
}
```

## 🔍 문제 해결

### 로그인은 되지만 Firebase에 데이터가 저장되지 않는 경우:
1. Firestore 보안 규칙 확인:
   ```javascript
   match /users/{userId} {
     allow read, write: if request.auth != null && request.auth.uid == userId;
   }
   ```
2. Firebase Console에서 Firestore가 활성화되어 있는지 확인
3. 네트워크 연결 확인

### Google 로그인이 안 되는 경우:
1. Firebase Console에서 Google 인증이 활성화되어 있는지 확인
2. Android의 경우 SHA-1 인증서 지문이 등록되어 있는지 확인
3. `google-services.json` 파일이 최신인지 확인

## ✅ 체크리스트

- [ ] Firebase Console에서 이메일/비밀번호 인증 활성화
- [ ] Firebase Console에서 Google 인증 활성화
- [ ] Firestore Database 생성 및 활성화
- [ ] Firestore 보안 규칙 설정 (`firestore.rules` 참고)
- [ ] 앱 실행 및 이메일 회원가입 테스트
- [ ] 앱 실행 및 Google 로그인 테스트
- [ ] Firebase Console에서 `users` 컬렉션에 데이터 저장 확인

## 📚 관련 파일

- `lib/services/auth_service.dart`: 인증 서비스
- `lib/features/auth/login_page.dart`: 로그인 페이지
- `lib/services/profile_service.dart`: 프로필 서비스
- `firestore.rules`: Firestore 보안 규칙

