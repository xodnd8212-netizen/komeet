# 푸시 알림 전략 및 신뢰성 계획

## 1. 목표
- 이벤트별(매칭, 새 메시지, 좋아요, 공지, 재참여 리마인더) 푸시 분리
- 수신 성공률 95% 이상, 무효 토큰 정리 자동화
- 사용자 알림 설정(메시지/매칭/마케팅) 세분화
- 24시간 미접속자 리마인더 → D1 리턴율 향상 모니터링

## 2. 시스템 구성
| 요소 | 역할 |
| --- | --- |
| Firebase Cloud Messaging | 토큰 발급, 푸시 전송 |
| Cloud Functions | 이벤트 트리거 처리, 토큰 정리, A/B 테스트 |
| Firestore | `notificationTokens`, `notificationSettings`, `notificationLogs` 저장 |
| BigQuery / Looker Studio | KPI 대시보드 |

## 3. 데이터 모델
```text
notificationTokens/{uid}_{tokenId}:
  uid: string
  token: string
  platform: android|ios|web|desktop
  deviceInfo: Map
  createdAt: serverTimestamp
  lastSeenAt: timestamp
  revoked: bool

notificationSettings/{uid}:
  message: bool
  match: bool
  likes: bool
  marketing: bool
  updatedAt: timestamp

notificationLogs/{id}:
  uid: string
  type: match|message|like|announcement|reengage
  payload: Map
  sentAt: serverTimestamp
  success: bool
  errorCode: string|null
  latencyMs: number
```

## 4. 이벤트 트리거
- **매칭**: Cloud Functions `onCreate matches` → 양측 토큰 조회 → `match` 타입 푸시
- **새 메시지**: `messages` onCreate → 수신자에게 `message` 타입 푸시, 채팅방 background sync
- **좋아요**: 단방향 좋아요 시 상대에게 알림(옵션) → 알림 끌 수 있도록 `notificationSettings.likes`
- **공지/브로드캐스트**: 어드민 콘솔에서 Cloud Functions HTTP 호출 → 토픽 기반 또는 대상자 리스트 발송
- **재참여 리마인더**: Cloud Scheduler + Cloud Functions  
  - 매일 09:00 JST 실행  
  - `users`에서 `lastActiveAt` 24시간 이상인 사용자 추출 → `reengage` 푸시  
  - A/B 테스트용으로 그룹 태깅(`variant: A/B`)

## 5. 신뢰성 확보
- **토큰 수집**: 앱 시작 시 `FirebaseMessaging.getToken()` → 변경 시 Firestore 업데이트
- **무효 토큰 정리**: 푸시 실패(`messaging/registration-token-not-registered`) 시 `revoked: true`, 30일 이상 미사용 토큰 삭제
- **재시도 전략**: Functions에서 지수 백오프 `retryConfig` 설정, 실패 로그 BigQuery 적재
- **QoS 모니터링**: `notificationLogs`를 BigQuery로 내보내 P95 latency/성공률 대시보드화
- **사용자 설정**: 앱 설정 화면에서 토글 → Firestore 업데이트 → Functions에서 respect

## 6. UX 고려
- 알림 허용 안내: 온보딩 중 전용 화면 + 거부 시 재설정 가이드
- 채팅 알림: 포그라운드 시 In-App Banner, 백그라운드 시 푸시
- 매칭 알림: 하이라이트 카드 + 바로 채팅방 이동 CTA
- 마케팅 알림: 수신 동의 체크, 거부 시 즉시 반영

## 7. 구현 단계
1. Firestore 컬렉션/보안 규칙 정의 (`notificationTokens`, `notificationSettings`, `notificationLogs`)
2. Flutter `PushNotificationService` 리팩터링 → 토큰 등록/제거, 설정 저장
3. Cloud Functions 모듈화  
   - `onMatchCreated`, `onMessageCreated`, `sendLikeNotification`, `sendAnnouncement`, `scheduleReengage`
4. Cloud Scheduler job 설정 (reengage, 무효 토큰 클린업)
5. BigQuery Export + Looker Studio 대시보드

## 8. 테스트 시나리오
| 시나리오 | 기대 결과 |
| --- | --- |
| 매칭 발생 | 양측 모두 3초 내 푸시 수신, 앱 열리면 채팅 화면으로 이동 |
| 메시지 수신 | 포그라운드에서 In-App Banner, 백그라운드에서는 시스템 푸시 |
| 토큰 만료 | Functions가 토큰 비활성화, 재전송 시 새로운 토큰 사용 |
| 알림 설정 끔 | 해당 타입 푸시 미전송, 로그에 “skipped-by-setting” |
| 리마인더 A/B | variant별 발송량/복귀율 BigQuery에서 분리 확인 |

