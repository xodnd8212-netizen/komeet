# 어드민 콘솔 & 대시보드 구현 계획

## 1. 목적
- 결제 및 코인 사용 흐름을 실시간 모니터링하고, 고객지원/환불/제재를 처리할 수 있는 운영 툴 제공
- 관리자 감사 로그와 통계 지표를 구축하여 Fraud 대응 및 비즈니스 의사결정 지원

## 2. 기술 스택 제안
- **프론트엔드**: `jp-kr-dating-app/web-admin` (React + TypeScript) 확장 또는 Flutter Web
- **백엔드**: Firebase Cloud Functions (HTTPS Callable / HTTPS REST), Firestore, Cloud Storage, BigQuery
- **인증/권한**: Firebase Auth 이메일/패스워드 + Custom Claims (`admin`, `support`, `analyst`)
- **시각화**: Looker Studio or Metabase + BigQuery export

## 3. 주요 화면 및 기능

### 3.1 로그인 / 권한
- 관리자는 Firebase Auth 계정으로 로그인
- Custom Claims에 따라 모듈 접근 제한: `admin` 풀권한, `support`(환불/코인조정만), `analyst`(조회만)
- 로그인 성공시 `admin_logs`에 기록

### 3.2 대시보드
- KPI 카드: 결제 매출, 구매 전환율, 평균 잔액, 일일 활성 구독자
- 차트: 일별 `coin_purchases` 건수/금액, `coin_transactions` 유형별 추이, 부스트/슈퍼라이크 사용률
- A/B 테스트 패널: 활성 실험 목록, variant별 전환률/ARPU

### 3.3 사용자 검색 & 상세
- 검색 필드: 이메일, UID, 닉네임, 전화번호
- 사용자 카드: 기본 정보, 가입일, 프로필 상태, 경고/정지 여부
- 코인 잔액, 무료 스와이프, 구독 상태, 최근 결제/사용 내역 (페이징)
- CTA: 코인 조정, 환불 요청, 정지/해제, Fraud 플래그

### 3.4 코인 조정/환불
- `adminAdjustBalance` 호출 UI (증가/차감/사유 입력)
- 환불 요청 시 `coin_purchases` 문서 상태를 `refund_requested`로 업데이트 → 승인 후 `refund` 처리 (결제 플랫폼 API 호출 포함)
- 모든 액션은 `admin_logs`에 기록, snackbar + Toaster 피드백

### 3.5 결제 모니터링
- `coin_purchases` 테이블 뷰: 필터(상태, 플랫폼, bundleId, 기간), 정렬(금액, 시간)
- 영수증 세부 정보 모달: purchase token, 검증 로그, bonus 지급 여부
- 빠른 Fraud 체크: 동일 IP/카드 반복, 고액 충전, 환불율 표시

### 3.6 코인 사용 내역
- `coin_transactions` 목록: 유형 필터(credit/debit, reason), 금액 범위, 기간
- `actions` 로그와 조인해 기능별 사용 통계 (부스트 성공률, 스페셜 좋아요 응답 등)
- CSV/Google Sheets 내보내기 버튼

### 3.7 알림 & 경보
- Fraud 탐지 트리거(`monitorTransactions`, `flagFraud`) 결과 표시
- Slack/Webhook 연동으로 경보 전달
- 매일/주간 리포트 메일 발송 예약 (Cloud Scheduler + Functions)

### 3.8 설정/구성
- 코인 번들, 보너스율, 보상 정책을 관리자 UI에서 수정 → `config` 컬렉션에 저장 → Cloud Functions에서 참조
- 실시간 저장/배포 시 백업본 생성, 롤백 기능 포함

## 4. 백엔드 API / Functions 변경
- 기존 Callable Functions 이외에 REST Endpoint 필요 시 Express 앱 사용
- 관리자 전용 함수 예시
  - `listCoinTransactions`, `listPurchases`, `adjustBalance`, `markAsFraud`, `updateBundleConfig`
  - 각 함수는 `context.auth.token.admin == true` 확인
- `coin_purchases`/`coin_transactions`에 `variant`, `sourceAction`, `device`, `country` 필드 추가하여 분석 지원

## 5. 보안 & 감사
- Firestore 규칙: `admin_logs`/`config`/`bundle_configs`는 admin claim만 쓰기 가능, `coin_purchases` 등 조회는 `admin/support/analyst` claim 허용
- Functions에서 모든 관리자 행동은 `admin_logs`에 `{adminUid, action, targetUid, delta, reason, createdAt}` 구조로 기록
- BigQuery Export: `coin_purchases`, `coin_transactions`, `actions`, `admin_logs` 일별 export → Fraud/지표 분석

## 6. 운영 프로세스
- 환불/차감 플로우 문서화 (고객센터 -> 검토 -> 결제 플랫폼 -> 코인 차감 -> 로그 기록)
- Fraud 탐지 시 대응 플로우: 자동 플래그 → 어드민 검토 → 정지/환불/조정
- SLA/권한 테이블: 예) `support`는 환불 50코인 이하만 허용

## 7. 일정 제안
| 단계 | 작업 | 예상 기간 |
| --- | --- | --- |
| 1 | 콘솔 UI 프레임 구축 + Auth 연동 | 3일 |
| 2 | 결제/트랜잭션 리스트 및 필터 구현 | 4일 |
| 3 | 사용자 상세, 코인 조정, 환불 흐름 | 5일 |
| 4 | 대시보드 차트, A/B 테스트 패널 | 4일 |
| 5 | 설정/구성 관리, Export 기능 | 3일 |
| 6 | QA, 문서화, 권한 검증 | 3일 |

총 약 22일(4.5주) 예상. 병렬로 BigQuery/Looker 작업 가능.

## 8. 후속 작업 제안
- Fraud 탐지 고도화: ML 기반 이상 탐지, Stripe Radar 연동 등
- Customer Support 연동: Zendesk/Freshdesk API 연결
- 모바일 운영 앱(Flutter Web)을 통해 현장에서도 처리 가능하도록 확장
