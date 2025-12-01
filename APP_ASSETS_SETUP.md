# 앱 아이콘 및 스플래시 화면 설정 가이드

이 문서는 KOMEET 앱의 아이콘과 스플래시 화면을 설정하는 방법을 안내합니다.

## 1. 앱 아이콘 설정

### 1.1 Android

#### 아이콘 이미지 준비
- 1024x1024px PNG 파일 준비
- 투명 배경 권장
- 아이콘은 중앙에 배치 (안전 영역 고려)

#### flutter_launcher_icons 사용 (권장)

1. 패키지 추가:
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. 설정 추가:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#1A1B2E"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

3. 아이콘 생성:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 1.2 iOS

#### 수동 설정
1. Xcode에서 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 열기
2. 필요한 크기의 아이콘 추가:
   - 20x20pt (@2x, @3x)
   - 29x29pt (@2x, @3x)
   - 40x40pt (@2x, @3x)
   - 60x60pt (@2x, @3x)
   - 1024x1024pt (1x)

### 1.3 Web

`web/manifest.json` 파일 수정:
```json
{
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

## 2. 스플래시 화면 설정

### 2.1 flutter_native_splash 사용 (권장)

1. 패키지 추가:
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.5
```

2. 설정 추가:
```yaml
flutter_native_splash:
  color: "#1A1B2E"
  image: assets/images/splash_logo.png
  android: true
  ios: true
  web: true
  web_image_mode: center
```

3. 스플래시 화면 생성:
```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

### 2.2 수동 설정

#### Android
`android/app/src/main/res/drawable/launch_background.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/splash_logo" />
    </item>
</layer-list>
```

#### iOS
`ios/Runner/Base.lproj/LaunchScreen.storyboard` 수정

## 3. 권장 아이콘 디자인

### 3.1 컬러 팔레트
- 메인 컬러: `#FF6EA9` (핑크)
- 배경: `#1A1B2E` (다크 블루)
- 텍스트: `#FFFFFF` (화이트)

### 3.2 디자인 요소
- 하트 아이콘 또는 커플 실루엣
- KOMEET 텍스트 또는 K 로고
- 그라데이션 효과 (선택사항)

## 4. 이미지 리소스 준비

### 4.1 필요한 파일
```
assets/
  icons/
    app_icon.png (1024x1024)
    app_icon_foreground.png (1024x1024, 투명 배경)
  images/
    splash_logo.png (512x512, 투명 배경)
```

### 4.2 온라인 도구
- [App Icon Generator](https://appicon.co/)
- [Icon Kitchen](https://icon.kitchen/)
- [Figma](https://www.figma.com/) - 디자인 도구

## 5. 적용 방법

### 5.1 자동 적용 (권장)

1. `pubspec.yaml`에 설정 추가
2. 이미지 파일 준비
3. 명령어 실행:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

### 5.2 수동 적용

각 플랫폼별 설정 파일에 직접 이미지 추가

## 6. 테스트

### 6.1 아이콘 확인
- 앱 설치 후 홈 화면에서 아이콘 확인
- 다양한 크기에서 선명도 확인

### 6.2 스플래시 화면 확인
- 앱 실행 시 스플래시 화면 표시 확인
- 로딩 시간에 맞는 표시 확인

## 참고 자료

- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
- [Material Design Icons](https://fonts.google.com/icons)

