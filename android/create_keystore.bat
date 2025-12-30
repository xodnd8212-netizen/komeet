@echo off
echo 키스토어 생성을 시작합니다...
echo.
echo 다음 정보를 입력해주세요:
echo - 키스토어 비밀번호 (6자 이상)
echo - 키 비밀번호 (보통 키스토어 비밀번호와 동일)
echo - 이름, 조직명 등 (엔터로 기본값 사용 가능)
echo.

cd app
keytool -genkey -v -keystore komeet-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias komeet

echo.
echo 키스토어가 생성되었습니다: app\komeet-release-key.jks
echo.
echo 이제 android\key.properties 파일을 생성하고 비밀번호를 입력해주세요.
pause



