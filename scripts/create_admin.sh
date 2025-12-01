#!/bin/bash
echo "어드민 계정 생성 스크립트 실행 중..."
cd "$(dirname "$0")/.."
flutter run -d windows --target=scripts/create_admin.dart





