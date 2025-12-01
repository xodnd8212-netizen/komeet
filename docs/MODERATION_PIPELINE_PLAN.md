# 콘텐츠 모더레이션 파이프라인 설계

## 1. 범위
- 대상 콘텐츠: 프로필 사진, 프로필 텍스트, 채팅 메시지(텍스트/이미지), 신고 첨부 파일
- 목표: 부적절 콘텐츠 90% 이상 사전 차단, 허위 양성/음성 모니터링, 자동 제재 워크플로 구축

## 2. 시스템 구성
| 계층 | 기술 | 역할 |
| --- | --- | --- |
| 클라이언트(Flutter) | image_picker, http, 커스텀 위젯 | 업로드 전 기본 필터링, 사용자 피드백 |
| Cloud Storage | Firebase Storage | 원본/검수용 이미지 저장, 메타데이터 제거 |
| Cloud Firestore | profiles, messages, moderationQueue, enforcements | 상태 관리 및 감사 로그 |
| Cloud Functions | Node.js 20 + Admin SDK | 텍스트/이미지 분석, 점수 계산, 자동 제재, 어드민 알림 |
| 외부 AI | Google Cloud Vision, Vertex AI, Perspective API | 욕설/음란/스팸 감지 |

## 3. 워크플로
### 3.1 이미지 업로드
1. 앱에서 사진 선택 → EXIF 제거 → Storage `uploads/{uid}/pending/{uuid}.jpg` 업로드
2. Cloud Functions `onFinalize` 트리거  
   - Vision SafeSearch, 얼굴 인식, nudity score 추출  
   - 퍼셉튜얼 해시 계산, 중복 감지  
   - 임계치 비교 → 통과 시 승인 경로로 이동, 실패 시 `moderationQueue`에 기록하고 사용자에게 “검수 중/거절” 상태 전달
3. 자동 차단 시 사용자에게 알림 및 대체 이미지 요청

### 3.2 텍스트 입력
1. 앱에서 1차 profanity 사전 필터 → 경고 배너 노출
2. Firestore 저장 시 Cloud Functions `onWrite`  
   - Vertex AI / Perspective API 호출 → Toxicity, Sexual, Threat score 계산  
   - 점수 누적: `userModerationStats/{uid}` 문서에 카운트 저장  
   - 임계치 초과 시 콘텐츠 비공개(`visible: false`) + `enforcements` 문서 추가

### 3.3 실시간 채팅
- 메시지 작성 직후 로컬 필터 적용, 서버 트리거에서 재검증  
- 심각도별 액션  
  - 경고: 채팅 메시지에 경고 배지, 사용자 알림  
  - 일시 정지: `accounts/{uid}.status = suspended`, 채팅방 읽기 전용  
  - 영구 정지: 인증 토큰 철회, 강제 로그아웃

### 3.4 신고 처리
1. 신고 버튼 → 유형 선택, 설명 입력, 증빙 업로드
2. Firestore `reports/{reportId}` 생성
3. Cloud Functions `onCreate`  
   - Slack/Email/Webhook으로 어드민에게 알림  
   - `moderationQueue`에 우선순위 삽입 (신고 횟수, 위험도 기반 정렬)  
   - 중복 신고 병합 시 기존 티켓에 카운트 누적

### 3.5 자동 제재
| 조건 | 액션 |
| --- | --- |
| 욕설/스팸 점수 누적 ≥ X | 경고 및 교육 메시지 |
| 음란/불법 의심 ≥ Y | 콘텐츠 비공개 + 어드민 승인 필요 |
| 반복 위반 ≥ Z | 계정 일시 정지, 재소명 폼 제공 |
| 악성 확정 | 영구 정지 + 차단 목록 등록 |

`enforcements/{id}` 문서에 (대상, 유형, 시간, 담당자/자동) 기록하여 감사 로그 유지.

## 4. 어드민 콘솔 통합
- 신고 큐 리스트: 상태 필터, 정렬, 임계치 하이라이트
- 유저 상세: 신고 이력, 점수, 제재 로그, 차단 해제/연장 버튼
- 자동 제재 알림: Slack/Email + 콘솔 플래그
- 허위 양성 처리: “재공개” 버튼 → 자동으로 사용자에게 알림 발송

## 5. 데이터 모델 초안
```text
moderationQueue/{id}:
  targetType: profile|message|image
  targetRef: <document path>
  scores: {toxicity: 0.7, nudity: 0.9, spam: 0.1}
  status: pending|auto_hidden|action_required|resolved
  priority: number
  reports: number
  createdAt: timestamp

enforcements/{id}:
  userId: string
  action: warn|suspend|ban
  reason: text
  issuedBy: system|admin_uid
  expiresAt: timestamp|null
  createdAt: timestamp

userModerationStats/{uid}:
  toxicityScore: number
  nudityScore: number
  spamScore: number
  lastUpdated: timestamp
```

## 6. 로드맵
1. Cloud Functions 프로젝트 구조화 (`functions/moderation` 모듈 분리)
2. Vision/Vertex API 키 발급 및 비용 한도 설정
3. Storage/Firestore 트리거 스캐폴드 작성, 테스트 데이터로 검증
4. Flutter 클라이언트에 업로드 상태(검수 중/거절) UI 추가
5. 어드민 콘솔(웹)에서 `moderationQueue` 목록/액션 구현
6. 모니터링: Cloud Logging, BigQuery로 점수/제재 통계 수집

