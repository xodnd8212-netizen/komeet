import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// 에러 모니터링 및 크래시 리포팅 서비스
class ErrorService {
  static FirebaseCrashlytics? _crashlytics;

  /// Crashlytics 초기화
  static Future<void> init() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Flutter 프레임워크 에러 핸들러 설정
      FlutterError.onError = (errorDetails) {
        // Crashlytics에 에러 전송
        _crashlytics?.recordFlutterFatalError(errorDetails);

        // 기존 에러 핸들러도 실행 (개발 중에는 콘솔에 출력)
        if (kDebugMode) {
          FlutterError.presentError(errorDetails);
        }
      };

      // 비동기 에러 핸들러 설정
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        return true;
      };

      AppLogger.info('Crashlytics 초기화 완료');
    } catch (e) {
      AppLogger.error('Crashlytics 초기화 실패', e);
      // Crashlytics 초기화 실패해도 앱은 계속 실행
    }
  }

  /// 비치명적 에러 기록
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    try {
      // 추가 데이터 설정
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          _crashlytics?.setCustomKey(key, value.toString());
        });
      }

      // 사용자 정보 설정
      if (reason != null) {
        _crashlytics?.log('Reason: $reason');
      }

      // 에러 기록
      await _crashlytics?.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );

      AppLogger.error('에러 기록됨 (Crashlytics)', error, stackTrace);
    } catch (e) {
      AppLogger.error('에러 기록 실패', e);
    }
  }

  /// 커스텀 로그 추가
  static void log(String message) {
    try {
      _crashlytics?.log(message);
      if (kDebugMode) {
        AppLogger.debug(message);
      }
    } catch (e) {
      // 무시
    }
  }

  /// 사용자 식별자 설정
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
    } catch (e) {
      AppLogger.error('사용자 ID 설정 실패', e);
    }
  }

  /// 사용자 속성 설정
  static Future<void> setUserProperty({
    required String key,
    required String value,
  }) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      AppLogger.error('사용자 속성 설정 실패', e);
    }
  }

  /// 테스트 크래시 발생 (개발용)
  static Future<void> testCrash() async {
    try {
      await _crashlytics?.crash();
    } catch (e) {
      // 무시 (의도적인 크래시)
    }
  }
}
