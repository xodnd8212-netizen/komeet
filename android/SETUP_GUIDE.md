# Release 서명 설정 가이드

## 단계 1: 키스토어 생성

PowerShell 또는 명령 프롬프트에서 다음 명령어를 실행하세요:

```powershell
cd android\app
keytool -genkey -v -keystore komeet-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias komeet
```

**입력 정보:**
- 키스토어 비밀번호: 6자 이상 (예: `yourpassword123`)
- 키 비밀번호: 보통 키스토어 비밀번호와 동일
- 이름, 조직명 등: 엔터로 기본값 사용 가능

## 단계 2: key.properties 파일 생성

`android\key.properties` 파일을 생성하고 다음 내용을 입력하세요:

```properties
storePassword=여기에_키스토어_비밀번호_입력
keyPassword=여기에_키_비밀번호_입력
keyAlias=komeet
storeFile=app/komeet-release-key.jks
```

**중요:** 
- `여기에_키스토어_비밀번호_입력`을 실제 비밀번호로 변경하세요
- `여기에_키_비밀번호_입력`을 실제 비밀번호로 변경하세요 (보통 키스토어 비밀번호와 동일)

## 단계 3: App Bundle 빌드

```powershell
cd c:\dev\komeet
flutter build appbundle
```

빌드된 파일: `build\app\outputs\bundle\release\app-release.aab`

## 보안 주의사항

- 키스토어 파일(`*.jks`)과 `key.properties` 파일은 Git에 커밋되지 않습니다 (`.gitignore`에 포함됨)
- 키스토어 파일과 비밀번호를 안전한 곳에 백업하세요 (분실 시 앱 업데이트 불가)
- 절대 공유하지 마세요


