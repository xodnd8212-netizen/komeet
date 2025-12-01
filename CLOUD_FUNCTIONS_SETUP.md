# Cloud Functions 설정 가이드

이 문서는 KOMEET 앱의 푸시 알림을 자동으로 전송하기 위한 Firebase Cloud Functions 설정 방법을 안내합니다.

## 개요

현재 앱은 Firestore에 알림 데이터를 저장하지만, 실제 푸시 알림 전송은 서버(Cloud Functions)에서 처리해야 합니다. 이 가이드에서는 Cloud Functions를 설정하여 매칭 및 채팅 알림을 자동으로 전송하는 방법을 설명합니다.

## 1. Node.js 설치

Cloud Functions는 Node.js를 사용합니다.

1. [Node.js 공식 사이트](https://nodejs.org/)에서 LTS 버전 다운로드 및 설치
2. 설치 확인:
   ```bash
   node --version
   npm --version
   ```

## 2. Firebase CLI 설치

```bash
npm install -g firebase-tools
```

## 3. Firebase 로그인

```bash
firebase login
```

## 4. Cloud Functions 프로젝트 초기화

### 4.1 프로젝트 구조 생성

```bash
# 프로젝트 루트로 이동
cd jp-kr-dating-app/komeet

# functions 디렉토리 생성
mkdir functions
cd functions

# Node.js 프로젝트 초기화
npm init -y
```

### 4.2 Firebase Functions 설치

```bash
npm install firebase-functions@latest firebase-admin@latest
```

## 5. Cloud Functions 코드 작성

`functions/index.js` 파일 생성:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 매칭 알림 전송
exports.sendMatchNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // 매칭 알림만 처리
    if (notification.type !== 'match') {
      return null;
    }

    try {
      // 수신자 FCM 토큰 가져오기
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.userId)
        .get();
      
      if (!userDoc.exists || !userDoc.data().fcmToken) {
        console.log('FCM 토큰이 없습니다:', notification.userId);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      
      // 발신자 프로필 가져오기
      const senderProfile = await admin.firestore()
        .collection('profiles')
        .doc(notification.fromUserId)
        .get();
      
      const senderName = senderProfile.exists 
        ? senderProfile.data().name 
        : '누군가';

      // 푸시 알림 메시지 구성
      const message = {
        notification: {
          title: '새로운 매칭!',
          body: `${senderName}님과 매칭되었습니다.`,
        },
        data: {
          type: 'match',
          matchId: notification.matchId,
          fromUserId: notification.fromUserId,
        },
        token: fcmToken,
      };

      // 알림 전송
      await admin.messaging().send(message);
      console.log('매칭 알림 전송 성공:', notification.userId);
      
      return null;
    } catch (error) {
      console.error('매칭 알림 전송 실패:', error);
      return null;
    }
  });

// 채팅 알림 전송
exports.sendChatNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // 채팅 알림만 처리
    if (notification.type !== 'chat') {
      return null;
    }

    try {
      // 수신자 FCM 토큰 가져오기
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.userId)
        .get();
      
      if (!userDoc.exists || !userDoc.data().fcmToken) {
        console.log('FCM 토큰이 없습니다:', notification.userId);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      
      // 발신자 프로필 가져오기
      const senderProfile = await admin.firestore()
        .collection('profiles')
        .doc(notification.fromUserId)
        .get();
      
      const senderName = senderProfile.exists 
        ? senderProfile.data().name 
        : '누군가';

      // 메시지 내용 (최대 100자)
      const messageText = notification.message 
        ? (notification.message.length > 100 
          ? notification.message.substring(0, 100) + '...' 
          : notification.message)
        : '새 메시지';

      // 푸시 알림 메시지 구성
      const message = {
        notification: {
          title: senderName,
          body: messageText,
        },
        data: {
          type: 'chat',
          chatId: notification.chatId,
          fromUserId: notification.fromUserId,
        },
        token: fcmToken,
      };

      // 알림 전송
      await admin.messaging().send(message);
      console.log('채팅 알림 전송 성공:', notification.userId);
      
      return null;
    } catch (error) {
      console.error('채팅 알림 전송 실패:', error);
      return null;
    }
  });
```

## 6. package.json 설정

`functions/package.json` 파일 수정:

```json
{
  "name": "functions",
  "description": "Cloud Functions for KOMEET",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^11.0.0",
    "firebase-functions": "^4.0.0"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.0.0"
  },
  "private": true
}
```

## 7. Firebase 프로젝트 연결

```bash
# 프로젝트 루트로 이동
cd jp-kr-dating-app/komeet

# Firebase 프로젝트 초기화 (이미 했다면 생략)
firebase init functions

# 프로젝트 선택
# 기존 프로젝트 선택 또는 새로 생성
```

## 8. Functions 배포

```bash
# Functions 배포
firebase deploy --only functions
```

## 9. 테스트

### 9.1 로컬 테스트 (선택사항)

```bash
# Functions 에뮬레이터 실행
firebase emulators:start --only functions

# 다른 터미널에서 테스트
# Firestore에 알림 데이터 추가하여 테스트
```

### 9.2 실제 배포 테스트

1. 앱에서 매칭 또는 채팅 메시지 전송
2. Firebase Console → Functions → 로그 확인
3. 푸시 알림 수신 확인

## 10. 비용 최적화

Cloud Functions는 호출 횟수와 실행 시간에 따라 과금됩니다. 비용을 절감하려면:

1. **중복 알림 방지**: 같은 사용자에게 짧은 시간 내 여러 알림이 가지 않도록 제한
2. **배치 처리**: 여러 알림을 한 번에 처리
3. **에러 재시도 제한**: 실패한 알림에 대한 재시도 제한

## 11. 고급 설정

### 11.1 스케줄링 (선택사항)

정기적으로 실행되는 함수:

```javascript
exports.scheduledFunction = functions.pubsub
  .schedule('every 5 minutes')
  .onRun((context) => {
    // 정기적으로 실행할 작업
    return null;
  });
```

### 11.2 HTTP 트리거 (선택사항)

외부에서 호출 가능한 함수:

```javascript
exports.sendCustomNotification = functions.https.onRequest(async (req, res) => {
  // HTTP 요청 처리
  res.json({ success: true });
});
```

## 12. 문제 해결

### 12.1 배포 오류

```bash
# Functions 로그 확인
firebase functions:log

# 특정 함수 로그 확인
firebase functions:log --only sendMatchNotification
```

### 12.2 권한 오류

Firebase Console → Functions → 설정에서 권한 확인

### 12.3 FCM 토큰 없음

- 사용자가 알림 권한을 허용했는지 확인
- FCM 토큰이 Firestore에 저장되었는지 확인

## 13. 모니터링

Firebase Console에서 다음을 모니터링할 수 있습니다:

- Functions 실행 횟수
- 실행 시간
- 에러 발생률
- 비용

## 참고 자료

- [Cloud Functions 문서](https://firebase.google.com/docs/functions)
- [FCM Admin SDK](https://firebase.google.com/docs/cloud-messaging/admin)
- [Firestore 트리거](https://firebase.google.com/docs/functions/firestore-events)

