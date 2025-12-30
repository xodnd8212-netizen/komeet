# 키스토어 생성 및 설정 가이드

## 1. 키스토어 생성

다음 명령어를 실행하여 키스토어를 생성하세요:

```bash
cd android\app
keytool -genkey -v -keystore komeet-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias komeet
```

또는 `create_keystore.bat` 스크립트를 실행하세요:

```bash
cd android
create_keystore.bat
```

키스토어 생성 시 다음 정보를 입력하세요:
- 키스토어 비밀번호 (6자 이상, 반드시 기억해두세요!)
- 키 비밀번호 (보통 키스토어 비밀번호와 동일)
- 이름, 조직명 등 (엔터로 기본값 사용 가능)

## 2. key.properties 파일 생성

`android\key.properties` 파일을 생성하고 다음 내용을 입력하세요:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=komeet
storeFile=app/komeet-release-key.jks
```

**중요:** 
- `YOUR_STORE_PASSWORD`와 `YOUR_KEY_PASSWORD`를 실제 비밀번호로 변경하세요
- 이 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다
- 키스토어 파일(`*.jks`)도 Git에 커밋되지 않습니다

## 3. App Bundle 빌드

키스토어와 key.properties 파일을 생성한 후:

```bash
flutter build appbundle
```

빌드된 파일: `build\app\outputs\bundle\release\app-release.aab`

## 보안 주의사항

- 키스토어 파일과 비밀번호는 절대 공유하지 마세요
- 키스토어 파일을 안전한 곳에 백업하세요 (분실 시 앱 업데이트 불가)
- 프로덕션 환경에서는 환경 변수나 CI/CD 시크릿을 사용하는 것을 권장합니다



