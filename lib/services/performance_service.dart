import 'package:firebase_performance/firebase_performance.dart';
import '../utils/logger.dart';

/// 성능 모니터링 서비스
class PerformanceService {
  static FirebasePerformance? _performance;

  /// Performance Monitoring 초기화
  static Future<void> init() async {
    try {
      _performance = FirebasePerformance.instance;
      AppLogger.info('Performance Monitoring 초기화 완료');
    } catch (e) {
      AppLogger.error('Performance Monitoring 초기화 실패', e);
      // Performance Monitoring 초기화 실패해도 앱은 계속 실행
    }
  }

  /// 트레이스 시작
  /// [name]: 트레이스 이름 (예: 'load_profile', 'send_message')
  /// 반환: Trace 객체 (stop() 호출 필요)
  static Trace? startTrace(String name) {
    try {
      return _performance?.newTrace(name);
    } catch (e) {
      AppLogger.error('트레이스 시작 실패', e);
      return null;
    }
  }

  /// 트레이스 시작 및 자동 종료 (async 함수용)
  /// [name]: 트레이스 이름
  /// [function]: 실행할 함수
  static Future<T> traceAsync<T>(
    String name,
    Future<T> Function() function,
  ) async {
    final trace = startTrace(name);
    try {
      trace?.start();
      final result = await function();
      trace?.stop();
      return result;
    } catch (e, stackTrace) {
      trace?.stop();
      rethrow;
    }
  }

  /// 커스텀 메트릭 추가
  /// [trace]: Trace 객체
  /// [metricName]: 메트릭 이름 (예: 'image_count', 'message_length')
  /// [value]: 메트릭 값
  static void addMetric(Trace? trace, String metricName, int value) {
    try {
      trace?.setMetric(metricName, value);
    } catch (e) {
      // 무시
    }
  }

  /// 커스텀 속성 추가
  /// [trace]: Trace 객체
  /// [attributeName]: 속성 이름
  /// [value]: 속성 값
  static void addAttribute(Trace? trace, String attributeName, String value) {
    try {
      trace?.putAttribute(attributeName, value);
    } catch (e) {
      // 무시
    }
  }

  /// HTTP 요청 추적
  /// [url]: 요청 URL
  /// [method]: HTTP 메서드 (GET, POST 등)
  /// [function]: 실행할 함수
  static Future<T> traceHttpRequest<T>(
    String url,
    String method,
    Future<T> Function() function,
  ) async {
    final trace = startTrace('http_request');
    try {
      trace?.start();
      addAttribute(trace, 'url', url);
      addAttribute(trace, 'method', method);
      final result = await function();
      trace?.stop();
      return result;
    } catch (e) {
      addAttribute(trace, 'error', e.toString());
      trace?.stop();
      rethrow;
    }
  }
}
