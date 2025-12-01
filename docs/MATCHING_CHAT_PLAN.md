# 매칭·채팅 개선 계획

## 1. 목표 KPI
- 첫 실행 30초 내 추천 카드 노출률 ≥ 95%
- 좋아요/패스 입력 후 반응 지연 < 200ms
- 상호 좋아요 시 1초 내 `matches/{matchId}` 및 채팅방 생성
- 채팅 이미지 업로드 < 3초, 매칭 알림 푸시 도달률 ≥ 95%

## 2. 현재 구조 요약
- `MatchService.getRecommendationsWithPagination`: Firestore에서 프로필 가져와 거리순 정렬
- `MatchService.likeUser`: `likes` 컬렉션 저장 후 상호 좋아요 시 `_createMatch`
- `_createMatch`: `matches` 문서 작성, `notifications` 컬렉션에 match 알림 추가
- `ChatService.createChatRoom`: 참가자 정렬 후 `chatRooms/{uid1_uid2}` 생성
- `ChatService.sendMessage`: Firestore `messages` 컬렉션에 저장, `notifications`에 채팅 알림 추가

## 3. 개선 포인트
### 3.1 추천 속도
- **사전 페치**: 로그인 직후 위치 정보 수집, `Future.wait`로 프로필/설정 동시 로드
- **인덱스 최적화**: Firestore 인덱스 `(gender, lastActive, city)` 등 생성, 거리 계산용 GeoHash 도입 검토
- **캐싱**: 클라이언트 로컬 캐시(마지막 추천 목록) 저장, 오프라인 상태에서도 뷰어 표시
- **Skeleton UI**: 추천 로딩 동안 플레이스홀더로 30초 SLA 충족

### 3.2 정렬 로직
- 거리 + 언어 매칭 + 최근 접속 가중치 계산  
  `score = w1*distanceScore + w2*languageScore + w3*activityScore`
- Firestore `profiles` 문서에 `languages`, `lastActive`, `age` 필드 유지
- 필터 조건: 신고/차단/정지 계정 제외(추후 `moderation` 데이터 연동)

### 3.3 좋아요/매칭 처리
- `likes` 컬렉션에 복합 키(`from_to`) 저장 → 중복 방지 및 조회 속도 개선
- Cloud Functions `onWrite likes`: 상호 좋아요 감지 → 트랜잭션으로 `matches` + `chatRooms` 생성 → 푸시 전송
- 로컬 UX: 좋아요 즉시 optimistic update, 서버 응답 지연 시 리트라이

### 3.4 채팅 경험
- **타이핑 표시**: `chatRooms/{id}/typing/{uid}` 문서에 상태 저장, 5초 TTL
- **읽음 상태 정확도**: `messages` 문서에 `seenBy` 배열 사용, 상대 디바이스 동기화
- **이미지 업로드 최적화**: Storage에 Resumable Upload + 썸네일 생성, 업로드 진행률 UI
- **메시지 동기화**: 오프라인 큐 → 재연결 시 순차 전송, 시간 동기화를 위한 서버 타임스탬프 사용

### 3.5 SLA 모니터링
- Cloud Functions에서 `likes`, `matches`, `chat` 이벤트 로그를 BigQuery에 스트림
- `processingTimeMs` 필드 기록, 95퍼센타일 모니터링
- 경고 임계치 초과 시 Slack/Email 알림

## 4. 구현 단계
1. Firestore 구조 리팩터링  
   - `likes/{fromUserId}_{toUserId}` doc  
   - `matches/{uid1_uid2}` doc에 `createdAt`, `score` 등 추가  
   - `chatRooms/{uid1_uid2}` doc에 `typing` 서브컬렉션
2. Cloud Functions 매칭 트리거 작성  
   - `likes` onWrite → 상호 여부 확인 → 트랜잭션 처리  
   - `matches` onCreate → FCM 전송 → Analytics 로깅
3. Flutter 클라이언트 업데이트  
   - `MatchService`에서 Cloud Functions 호출 혹은 REST endpoint 사용  
   - 실시간 스트림 기반 추천(UI) 개선, 로딩 스피너 최적화  
   - 채팅 입력창에 타이핑 인디케이터, 신고/차단 버튼 배치
4. 테스트 자동화  
   - 통합 테스트: 좋아요 → 상호 좋아요 → 채팅방 여부 확인  
   - 성능 테스트: Firebase Emulator Suite + Locust/Cloud Tasks로 부하 측정

## 5. 데이터 모델 제안
```text
likes/{from_to}:
  fromUserId: string
  toUserId: string
  createdAt: serverTimestamp

matches/{uid1_uid2}:
  participantIds: [uid1, uid2]
  createdAt: serverTimestamp
  lastMessageAt: timestamp|null
  status: active|ended|blocked

chatRooms/{uid1_uid2}:
  participantIds: [uid1, uid2]
  createdAt: serverTimestamp
  lastMessage: string
  lastMessageAt: timestamp
  typing: subcollection { uid: { isTyping: bool, updatedAt } }
```

## 6. 로드맵
1. Firestore 인덱스/데이터 모델 정리 문서화
2. Cloud Functions PoC (likes onWrite → matches/notification)
3. 클라이언트 optimistic 업데이트 및 타이핑 UI 구현
4. BigQuery 대시보드로 SLA 모니터링 구축
5. 실 기기/네트워크 조건별 체감 지연 측정 및 튜닝

