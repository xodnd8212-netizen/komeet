# 인증 테스트 가이드

## ✅ 완료된 작업

### 1. 로그인 방법 정리
- ✅ **이메일/비밀번호**: 회원가입 및 로그인 가능
- ✅ **Google 로그인**: 정상 작동
- ❌ 카카오/네이버/Apple 로그인 제거됨

### 2. Firebase 연동
- ✅ 로그인 성공 시 자동으로 Firestore `users` 컬렉션에 사용자 정보 저장
- ✅ 저장되는 필드:
  - `uid`: 사용자 고유 ID
  - `email`: 이메일 주소
  - `displayName`: 표시 이름 (Google 로그인 시)
  - `photoURL`: 프로필 사진 URL (Google 로그인 시)
  - `createdAt`: 계정 생성 시간
  - `updatedAt`: 마지막 업데이트 시간
  - `lastLoginAt`: 마지막 로그인 시간

## 🧪 테스트 방법

### 테스트 1: 이메일/비밀번호 회원가입

1. **앱 실행**
2. **이메일 입력**: 예) `test@example.com`
3. **비밀번호 입력**: 6자 이상 (예: `test123`)
4. **"회원가입" 버튼 클릭**
5. **확인 사항**:
   - 로그인 성공 메시지 표시
   - 프로필 페이지로 이동
   - Firebase Console → Firestore → `users` 컬렉션에서 데이터 확인

**예상 결과:**
```json
{
  "uid": "생성된_UID",
  "email": "test@example.com",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z"
}
```

### 테스트 2: 이메일/비밀번호 로그인

1. **앱 실행** (또는 로그아웃 후)
2. **회원가입한 이메일과 비밀번호 입력**
3. **"로그인" 버튼 클릭**
4. **확인 사항**:
   - 로그인 성공
   - Firebase Console에서 `lastLoginAt` 필드가 업데이트되었는지 확인

### 테스트 3: Google 로그인

1. **앱 실행**
2. **"Google 계정으로 계속하기" 버튼 클릭**
3. **Google 계정 선택**
4. **확인 사항**:
   - 로그인 성공
   - Firebase Console → Firestore → `users` 컬렉션에서 데이터 확인
   - `displayName`과 `photoURL`이 저장되었는지 확인

**예상 결과:**
```json
{
  "uid": "Google_UID",
  "email": "user@gmail.com",
  "displayName": "사용자 이름",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z"
}
```

### 테스트 4: 특정 UID 확인

UID `jusLNuXpKqeqmPPEKWNoimSUPUy2`의 사용자 데이터 확인:

**Firebase Console에서:**
1. Firebase Console → Firestore Database
2. `users` 컬렉션 선택
3. 문서 ID `jusLNuXpKqeqmPPEKWNoimSUPUy2` 확인

**코드에서 확인:**
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc('jusLNuXpKqeqmPPEKWNoimSUPUy2')
    .get();

if (userDoc.exists) {
  print('사용자 데이터: ${userDoc.data()}');
} else {
  print('사용자 데이터가 없습니다.');
}
```

## 🔍 Firebase Console 확인 방법

### 1. Firestore 데이터 확인
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (komeet-6caca)
3. 왼쪽 메뉴 → **Firestore Database**
4. `users` 컬렉션 클릭
5. 문서 확인

### 2. Authentication 사용자 확인
1. Firebase Console → **Authentication**
2. **Users** 탭에서 로그인한 사용자 목록 확인
3. 사용자 UID 클릭하여 상세 정보 확인

## ⚠️ 문제 해결

### 로그인은 되지만 Firebase에 데이터가 저장되지 않는 경우:

1. **Firestore 보안 규칙 확인**
   - Firebase Console → Firestore Database → 규칙 탭
   - 다음 규칙이 있는지 확인:
   ```javascript
   match /users/{userId} {
     allow read, write: if request.auth != null && request.auth.uid == userId;
   }
   ```

2. **Firestore 활성화 확인**
   - Firebase Console → Firestore Database
   - 데이터베이스가 생성되어 있는지 확인

3. **네트워크 연결 확인**
   - 인터넷 연결 상태 확인
   - 방화벽 설정 확인

### Google 로그인이 안 되는 경우:

1. **Firebase Console 설정 확인**
   - Authentication → Sign-in method → Google 활성화 확인

2. **Android SHA-1 인증서 지문 확인**
   ```bash
   keytool -list -v -keystore android\app\komeet-release-key.jks -alias komeet -storepass komeet123456 | findstr "SHA1"
   ```
   - Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱 → SHA 인증서 지문에 등록되어 있는지 확인

3. **google-services.json 확인**
   - `android/app/google-services.json` 파일이 최신인지 확인

## 📊 테스트 체크리스트

- [ ] 이메일/비밀번호 회원가입 성공
- [ ] Firebase `users` 컬렉션에 데이터 저장 확인
- [ ] 이메일/비밀번호 로그인 성공
- [ ] `lastLoginAt` 필드 업데이트 확인
- [ ] Google 로그인 성공
- [ ] Google 로그인 시 `displayName`, `photoURL` 저장 확인
- [ ] 특정 UID (`jusLNuXpKqeqmPPEKWNoimSUPUy2`) 데이터 확인

## 🎯 다음 단계

로그인이 정상 작동하면:
1. 프로필 생성 및 저장 테스트
2. 매칭 기능 테스트
3. 채팅 기능 테스트
