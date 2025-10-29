# jp-kr-dating-app

## 프로젝트 개요
이 프로젝트는 일본인 여성과 한국인 남성을 연결하는 소개팅 앱입니다. 모바일 애플리케이션과 웹 관리 대시보드, 서버 API로 구성되어 있습니다.

## 기술 스택
- **프론트엔드**: React Native, TypeScript, Zustand/Redux, React Query, Zod
- **백엔드**: Node.js, Express/Fastify, Prisma, JWT
- **데이터베이스**: PostgreSQL
- **CI/CD**: GitHub Actions
- **컨테이너화**: Docker

## 기능
- 사용자 인증 및 프로필 관리
- 매칭 시스템
- 채팅 기능
- 푸시 알림
- 결제 시스템 통합
- 파일 업로드 및 관리

## 설치 및 실행
1. **환경 변수 설정**: `.env.example` 파일을 복사하여 `.env` 파일을 생성하고 필요한 환경 변수를 설정합니다.
2. **의존성 설치**:
   - 서버: `cd server && npm install`
   - 모바일 앱: `cd mobile-app && npm install`
   - 웹 관리 대시보드: `cd web-admin && npm install`
3. **데이터베이스 마이그레이션**: `cd server && npm run migrate`
4. **서버 실행**: `cd server && npm run start`
5. **모바일 앱 실행**: `cd mobile-app && npm run start`
6. **웹 관리 대시보드 실행**: `cd web-admin && npm run start`

## 테스트
- 단위 테스트: `npm test` 명령어로 각 애플리케이션의 테스트를 실행합니다.

## 기여
기여를 원하시는 분은 이 저장소를 포크한 후, 변경 사항을 커밋하고 풀 리퀘스트를 제출해 주세요.

## 라이센스
이 프로젝트는 MIT 라이센스 하에 배포됩니다.