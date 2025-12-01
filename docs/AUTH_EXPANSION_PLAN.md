# 인증 확장 설계 (Apple / 전화번호 / 익명 업그레이드)

## 1. 목표 요약
- **지원 채널**: Apple, Google, Kakao, Naver, 전화번호 OTP, 이메일(백업).
- **핵심 경험**: 설치 직후 간편 로그인 → 95% 이상 2분 내 성공, 권한 거부 시 대체 UX 제공.
- **보안 요구**: OTP 남용 방지(1일 시도 횟수 제한), 민감 작업 전 재인증, 스토어 심사 체크리스트 충족.

## 2. 아키텍처 개요
| 구성 요소 | 역할 | 구현 항목 |
| --- | --- | --- |
| Firebase Authentication | 계정 생성·토큰 발급 | Apple, Phone Provider 활성화, 다국어 에러 처리 |
| Cloud Functions (Node 20) | OTP 레이트리밋, 감사로그 | Callable Function으로 시도 횟수 집계, 관리자 알림 |
| Firestore | 사용자 메타데이터 | 로그인 채널, 마지막 reauth 시점, 전화번호 인증 기록 저장 |
| Cloud Storage | 약관/정책 파일 | 정책 동의 버전 관리 |
| Flutter 앱 | UI/UX | 로그인 화면 업데이트, 익명→업그레이드 흐름, 오류 로깅 |

## 3. 세부 구현 단계
### 3.1 Apple 로그인
1. Apple Developer 계정에서 Service ID 생성, Firebase 콘솔에 웹 도메인 및 리디렉션 URL 등록.  
2. Firebase Auth에서 Apple 제공자 활성화 → `Services ID`, `Secret Key`, `Team ID`, `Key ID` 입력.  
3. Flutter: `sign_in_with_apple` 패키지 추가, iOS 플랫폼 설정(`Sign In With Apple` capability, `Reverse Client ID` 스킴).  
4. `AuthService`에 `signInWithApple()` 추가 → iOS/macOS에서는 native flow, Android/Web은 Firebase 팝업(OAuth).  
5. 로그인 UI에 Apple 버튼 추가.  
6. QA: iOS 기기/시뮬레이터에서 신규가입·재로그인 테스트, 토큰 만료 시 재인증 처리.

### 3.2 전화번호 OTP
1. Firebase 콘솔에서 Phone Provider 활성화, 테스트 번호 등록.  
2. Cloud Functions: `onCall verifyOtpRequest(data)`  
   - `data.phone`, `deviceId`, `ip` 기준 일일 제한(예: 5회).  
   - Firestore `otpAttempts/{date}` 문서에 증분, 임계 초과 시 오류 반환.  
3. Flutter UI 흐름  
   - 로그인 화면에 `전화번호로 계속` 버튼 추가.  
   - 단계: 번호 입력 → Functions 호출로 레이트리밋 확인 → `FirebaseAuth.verifyPhoneNumber` 호출 → OTP 입력 → `PhoneAuthProvider.credential`로 로그인.  
   - 2FA 시나리오 대비 재전송 카운트다운, 실패 시 친절한 메시지.  
4. reCAPTCHA/앱 검사: Android는 SafetyNet/AppCheck, iOS는 팝업 자동 적용.  
5. 성공 후 `users/{uid}` 프로필에 전화번호, 마지막 인증 시각 저장.

### 3.3 익명 로그인 → 업그레이드
1. 초기 온보딩에서 익명 계정 생성(`AuthService.signInAnonymously`).  
2. 프로필 작성·추천 탐색은 가능하되 “좋아요/채팅/결제” 직전 업그레이드 모달 표시.  
3. 익명 → 정식 계정 전환: `linkWithCredential` 사용(이메일/소셜/전화).  
4. 실패 대비 롤백 전략: `authStateChanges` 구독으로 상태 업데이트, Firestore 사용자 문서 migrate.

### 3.4 재인증 플로우
1. 민감 작업(결제, 계정 삭제, 전화번호 변경) 전 `AuthService.reauthenticate(provider)` API 노출.  
2. UI에서 인증 채널 선택 후 `reauthenticateWithCredential`.  
3. 실패 시 재시도 안내 및 로그 캡처.

## 4. UX / UI 업데이트
- 로그인 화면 버튼 순서: Apple → Google → Kakao → Line(추가 시) → Naver → Phone → Email.  
- 권한 거부/네트워크 실패 시 대체 UX: 고객센터 안내 + 다른 로그인 수단 제시.  
- 19+ 뱃지, 정책 링크를 로그인 하단에 상시 노출.  
- 인증 진행 중 로딩/취소 버튼, 오류 메시지 다국어화(`i18n` 갱신 필요).

## 5. QA 체크리스트
| 시나리오 | 기기/플랫폼 | 기대 결과 |
| --- | --- | --- |
| Apple 신규 가입 | iOS 17 실기기 | 계정 생성, Firebase 유저 문서 작성 |
| Apple 재로그인 | iOS/macOS | 5초 내 로그인, 이전 프로필 유지 |
| Phone OTP 정상 | Android 14, iOS 17 | OTP 수신, 2분 내 인증 완료 |
| Phone OTP 과다 시도 | Functions Rate Limit | “시도 횟수 초과” 메시지, 로그 기록 |
| 익명 → Google 업그레이드 | Android | 좋아요 직전 모달 → 성공 후 match 가능 |
| 재인증 후 결제 | iOS IAP 샌드박스 | 재인증 성공 시 결제 진행 |

## 6. 작업 분할 제안
1. **백엔드 담당**  
   - Firebase 콘솔 설정(Apple/Phone)  
   - Cloud Functions: OTP 레이트리밋, 감사로그  
2. **모바일 담당**  
   - Flutter Auth UI/서비스 확장  
   - 권한/에러 UX, i18n 업데이트  
3. **QA/운영**  
   - 테스트 케이스 작성, 스토어 심사용 문서 초안 업데이트

## 7. 의존성 & 위험
- Apple Developer 계정 및 유료 멤버십 필요.  
- 전화번호 인증은 국가별 SMS 정책/비용에 민감 → 월별 예산 모니터링 대시보드 필요.  
- 익명 업그레이드 중 복수 채널 연결 시 충돌 가능 → `linkWithCredential` 오류 처리 필수.  
- QA 환경에서 SMS 수신 어려울 경우 `Firebase Auth` 테스트 번호 사용.

## 8. 다음 단계
1. Firebase 콘솔에서 Apple/Phone Provider 활성화 및 구성 파일 업데이트.  
2. Flutter 프로젝트에 `sign_in_with_apple`, `flutter_apple_sign_in`, `firebase_auth` 최신 버전 확인, `firebase_ui_auth` 도입 검토.  
3. Cloud Functions 프로젝트 초기화 후 레이트리밋 함수 스캐폴드 작성.  
4. 로그인 UI 리팩터링 및 버튼/모달 배치 설계 → Figma/디자인 시안 확인.  
5. QA 체크리스트 기반 시뮬레이션 계획 수립.

