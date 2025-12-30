@echo off
echo ========================================
echo Release 서명 설정 가이드
echo ========================================
echo.

REM 키스토어 파일 확인
if exist "app\komeet-release-key.jks" (
    echo [OK] 키스토어 파일이 존재합니다: app\komeet-release-key.jks
) else (
    echo [필요] 키스토어 파일이 없습니다.
    echo.
    echo 키스토어를 생성하려면 다음 명령어를 실행하세요:
    echo   cd app
    echo   keytool -genkey -v -keystore komeet-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias komeet
    echo.
    echo 또는 create_keystore.bat 스크립트를 실행하세요.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo key.properties 파일 설정
echo ========================================
echo.

if exist "key.properties" (
    echo [경고] key.properties 파일이 이미 존재합니다.
    echo 기존 파일을 덮어쓰시겠습니까? (Y/N)
    set /p overwrite=
    if /i not "%overwrite%"=="Y" (
        echo 취소되었습니다.
        pause
        exit /b 0
    )
)

echo 키스토어 비밀번호를 입력하세요:
set /p storePassword=

echo 키 비밀번호를 입력하세요 (보통 키스토어 비밀번호와 동일):
set /p keyPassword=

(
echo storePassword=%storePassword%
echo keyPassword=%keyPassword%
echo keyAlias=komeet
echo storeFile=app/komeet-release-key.jks
) > key.properties

echo.
echo [완료] key.properties 파일이 생성되었습니다.
echo.
echo 이제 다음 명령어로 App Bundle을 빌드할 수 있습니다:
echo   flutter build appbundle
echo.
pause



