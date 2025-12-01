import 'logger.dart';

/// 성능 모니터링 유틸리티
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};

  /// 작업 시작 시간 기록
  static void start(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// 작업 종료 및 소요 시간 기록
  static void end(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (duration.inMilliseconds > 1000) {
        // 1초 이상 걸리는 작업은 경고
        AppLogger.warning('느린 작업 감지', {
          'operation': operation,
          'durationMs': duration.inMilliseconds,
        });
      } else {
        AppLogger.debug('작업 완료', {
          'operation': operation,
          'durationMs': duration.inMilliseconds,
        });
      }
    }
  }

  /// 비동기 작업 성능 측정
  static Future<T> measure<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    start(operation);
    try {
      final result = await action();
      end(operation);
      return result;
    } catch (e, stackTrace) {
      end(operation);
      AppLogger.error('작업 실패', e, stackTrace, {'operation': operation});
      rethrow;
    }
  }

  /// 동기 작업 성능 측정
  static T measureSync<T>(
    String operation,
    T Function() action,
  ) {
    start(operation);
    try {
      final result = action();
      end(operation);
      return result;
    } catch (e, stackTrace) {
      end(operation);
      AppLogger.error('작업 실패', e, stackTrace, {'operation': operation});
      rethrow;
    }
  }
}

