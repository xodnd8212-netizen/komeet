# 개발자 테스트 가이드

## 🎯 현재 상태

이 프로젝트는 **이메일/비밀번호**와 **Google 로그인**만 지원합니다.

## 🚀 빠른 시작 (다른 개발자용)

### 1. 프로젝트 클론
```bash
git clone https://github.com/xodnd8212-netizen/komeet.git
cd komeet
```

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. Firebase 설정 (필수)

#### 3.1 Firebase 프로젝트 확인
- Firebase 프로젝트: `komeet-6caca`
- 프로젝트 ID: `komeet-6caca`

#### 3.2 Authentication 활성화
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `komeet-6caca`
3. **Authentication** → **Sign-in method**:
   - ✅ **이메일/비밀번호**: 활성화
   - ✅ **Google**: 활성화

#### 3.3 Firestore Database 활성화
1. Firebase Console → **Firestore Database**
2. 데이터베이스가 없으면 생성
3. 위치: `asia-northeast1` (도쿄) 권장

#### 3.4 google-services.json 다운로드
1. Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱
2. `google-services.json` 다운로드
3. 파일을 `android/app/google-services.json`에 복사

**중요:** `google-services.json` 파일은 Git에 커밋되지 않습니다. 각 개발자가 직접 다운로드해야 합니다.

### 4. 앱 실행
```bash
flutter run
```

## 🧪 테스트 시나리오

### 시나리오 1: 이메일/비밀번호 회원가입

1. **앱 실행**
2. **이메일 입력**: 예) `developer@test.com`
3. **비밀번호 입력**: 6자 이상 (예: `test123`)
4. **"회원가입" 버튼 클릭**
5. **확인 사항**:
   - ✅ 로그인 성공
   - ✅ 프로필 페이지로 이동
   - ✅ Firebase Console → Firestore → `users` 컬렉션에서 데이터 확인

**Firebase에서 확인할 데이터:**
```json
{
  "uid": "생성된_UID",
  "email": "developer@test.com",
  "createdAt": "서버_타임스탬프",
  "updatedAt": "서버_타임스탬프",
  "lastLoginAt": "서버_타임스탬프"
}
```

### 시나리오 2: 이메일/비밀번호 로그인

1. **앱 실행** (또는 로그아웃 후)
2. **회원가입한 이메일과 비밀번호 입력**
3. **"로그인" 버튼 클릭**
4. **확인 사항**:
   - ✅ 로그인 성공
   - ✅ Firebase Console에서 `lastLoginAt` 필드 업데이트 확인

### 시나리오 3: Google 로그인

1. **앱 실행**
2. **"Google 계정으로 계속하기" 버튼 클릭**
3. **Google 계정 선택**
4. **확인 사항**:
   - ✅ 로그인 성공
   - ✅ Firebase Console → Firestore → `users` 컬렉션에서 데이터 확인
   - ✅ `displayName`과 `photoURL`이 저장되었는지 확인

**Firebase에서 확인할 데이터:**
```json
{
  "uid": "Google_UID",
  "email": "user@gmail.com",
  "displayName": "사용자 이름",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "createdAt": "서버_타임스탬프",
  "updatedAt": "서버_타임스탬프",
  "lastLoginAt": "서버_타임스탬프"
}
```

### 시나리오 4: 특정 UID 확인

UID `jusLNuXpKqeqmPPEKWNoimSUPUy2`의 사용자 데이터 확인:

**Firebase Console에서:**
1. Firebase Console → Firestore Database
2. `users` 컬렉션 선택
3. 문서 ID `jusLNuXpKqeqmPPEKWNoimSUPUy2` 확인

**코드에서 확인:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
2. 프로젝트 선택: `komeet-6caca`
3. 왼쪽 메뉴 → **Firestore Database**
4. `users` 컬렉션 클릭
5. 문서 확인

### 2. Authentication 사용자 확인
1. Firebase Console → **Authentication**
2. **Users** 탭에서 로그인한 사용자 목록 확인
3. 사용자 UID 클릭하여 상세 정보 확인

## ⚠️ 문제 해결

### 로그인이 안 되는 경우

1. **Firebase Console 확인**:
   - Authentication → Sign-in method에서 이메일/비밀번호와 Google이 활성화되어 있는지 확인
   - `FIREBASE_AUTH_SETUP.md` 참고

2. **google-services.json 확인**:
   - 파일이 `android/app/google-services.json`에 있는지 확인
   - 파일이 최신인지 확인

3. **Firestore 활성화 확인**:
   - Firestore Database가 생성되어 있는지 확인

### Google 로그인이 안 되는 경우

1. **SHA-1 인증서 지문 확인** (Android):
   ```bash
   # 디버그 키스토어
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1"
   ```
   - Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱 → SHA 인증서 지문에 등록

2. **Firebase Console 설정 확인**:
   - Authentication → Sign-in method → Google 활성화 확인

### Firebase에 데이터가 저장되지 않는 경우

1. **Firestore 보안 규칙 확인**:
   ```javascript
   match /users/{userId} {
     allow read, write: if request.auth != null && request.auth.uid == userId;
   }
   ```

2. **네트워크 연결 확인**

3. **에러 로그 확인**: 앱 실행 시 콘솔에 에러 메시지 확인

## 📋 테스트 체크리스트

다른 개발자가 테스트할 때 확인할 사항:

- [ ] 프로젝트 클론 성공
- [ ] `flutter pub get` 성공
- [ ] Firebase Console에서 프로젝트 접근 가능
- [ ] `google-services.json` 파일 다운로드 및 배치 완료
- [ ] 앱 실행 성공
- [ ] 이메일/비밀번호 회원가입 성공
- [ ] Firebase `users` 컬렉션에 데이터 저장 확인
- [ ] 이메일/비밀번호 로그인 성공
- [ ] Google 로그인 성공 (선택사항)
- [ ] 특정 UID (`jusLNuXpKqeqmPPEKWNoimSUPUy2`) 데이터 확인

## 📚 참고 문서

- **`README.md`**: 프로젝트 개요 및 빠른 시작
- **`FIREBASE_SETUP.md`**: Firebase 프로젝트 설정 가이드
- **`FIREBASE_AUTH_SETUP.md`**: Firebase Authentication 설정 및 문제 해결
- **`TESTING_GUIDE.md`**: 상세 테스트 가이드
- **`AUTH_SETUP_COMPLETE.md`**: 인증 설정 완료 가이드

## 🔗 중요 링크

- **GitHub 저장소**: https://github.com/xodnd8212-netizen/komeet
- **Firebase Console**: https://console.firebase.google.com/
- **프로젝트**: komeet-6caca

## 💡 팁

1. **첫 실행 시**: Firebase 설정이 완료되지 않으면 앱이 실행되지 않을 수 있습니다. `google-services.json` 파일을 반드시 추가하세요.

2. **테스트 계정**: 테스트용 이메일 계정을 여러 개 만들어서 테스트하는 것을 권장합니다.

3. **Firebase 콘솔**: 로그인 후 반드시 Firebase Console에서 데이터가 저장되었는지 확인하세요.

4. **에러 메시지**: 앱에서 빨간색 스낵바로 표시되는 에러 메시지를 확인하세요.
