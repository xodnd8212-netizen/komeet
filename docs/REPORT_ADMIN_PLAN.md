# 신고·차단 및 운영 콘솔 개선안

## 1. 요구 사항 정리
- 앱 내 신고 유형(스팸/욕설/노출/미성년/불법 등) 선택 + 증빙 업로드
- 신고 즉시 어드민 큐 반영 (<2초), 차단 시 상호 미노출/채팅 비활성화
- 어드민 콘솔: 검색(UID/이메일/닉네임), 신고 큐 필터/정렬, 제재(경고/일시정지/영구정지), 공지 브로드캐스트, 감사 로그
- 반복 위반 시 자동 제재, 재소명 프로세스

## 2. 데이터 모델 제안
```text
reports/{reportId}:
  reporterId: string
  targetUserId: string
  targetType: profile|message|image|chat
  reasonCode: spam|abuse|nudity|minor|illegal|other
  description: string
  evidenceUrls: [string]
  status: pending|investigating|actioned|dismissed
  priority: number
  createdAt: serverTimestamp
  updatedAt: timestamp

blocks/{uid}/targets/{targetUid}:
  createdAt: serverTimestamp
  reason: reportId|null

adminActions/{actionId}:
  adminId: string
  userId: string
  action: warn|suspend|ban|unban|note|broadcast
  payload: Map
  createdAt: serverTimestamp
```

## 3. 앱 기능
- **신고 버튼 위치**: 프로필 카드, 채팅 상단, 설정 > 지원
- **UI 흐름**: 신고 유형 선택 → 설명/증빙 입력 → 제출 후 토스트 + 차단 권장
- **차단 로직**: `blocks` 컬렉션에 양방향 문서 작성 → 매칭/채팅/추천 쿼리에서 제외
- **재소명**: 제재된 계정은 앱 진입 시 Appeal Form 화면으로 이동, Firestore `appeals` 컬렉션 생성

## 4. 운영 콘솔 (웹)
- 프레임워크: 기존 레포 `jp-kr-dating-app/web-admin` 확장
- **모듈**
  - Dashboard: 통계(신고 건수, 처리 SLA, 제재 상태)
  - Reports: 필터(상태, 이유, 기간), 정렬(우선순위), 상세 뷰(증빙 미디어 프리뷰)
  - Users: 검색, 상태 변경, 로그 보기
  - Broadcast: FCM 토픽 혹은 사용자 목록에 공지 전송
  - Audit Log: `adminActions` 리스트, diff, 주석
- **역할 기반 접근 제어**: Firebase Auth + Custom Claims (admin, reviewer, support)
- **실시간 업데이트**: Firestore Snapshot Listener 또는 Cloud Functions Pub/Sub Webhook

## 5. 워크플로
1. 사용자 신고 → Firestore `reports` 생성 → Cloud Functions `onCreate`  
   - 우선순위 계산(신고 횟수, reasonCode 가중치)  
   - Slack/Email 알림, `moderationQueue`와 연동
2. 어드민 콘솔에서 티켓 열람 → 증빙 확인 → 액션 선택  
   - 액션 버튼 클릭 시 Cloud Functions HTTP 호출 → Firestore 업데이트 + `adminActions` 기록  
   - 사용자 제재 상태 업데이트(`users/{uid}.status`)
3. 제재 결과 자동 반영  
   - 차단: `blocks` 컬렉션 업데이트  
   - 일시 정지: `accounts/{uid}.suspension` 필드 + 유효기간 → 앱 최초 진입 시 체크하여 로그아웃
4. 재소명 처리  
   - 사용자 Appeal 제출 시 `appeals/{id}` 생성  
   - 어드민이 검토 후 해제 시 `adminActions` 기록 + 사용자 알림

## 6. SLA / 모니터링
- 신고 접수 → 콘솔 표시 < 2초 (Firestore 실시간 스트림 사용)
- 처리까지 걸린 시간 BigQuery 로깅, 주간 보고서 생성
- 감사 로그 누락 방지: 모든 Functions/어드민 액션에서 `adminActions` 문서 생성
- 보안: 어드민 콘솔 Cloud Run + Identity-Aware Proxy 또는 Firebase Hosting + App Check

## 7. 로드맵
1. 데이터 모델 및 Firestore 규칙 초안 작성 (`firestore.rules` 업데이트)
2. Flutter 앱에 신고/차단 UI 추가, `ReportService`/`BlockService` 구현
3. Cloud Functions: 신고 알림, 제재 처리, 감사 로그 기록
4. 웹 어드민 초기 화면 (Reports 리스트, 상세, 액션 버튼)
5. QA: 신고→제재→차단→재소명 전체 플로우 시나리오 테스트

