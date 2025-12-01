import 'dart:collection';

/// Rate Limiting 유틸리티 (클라이언트 측 기본 보호)
class RateLimiter {
  static final Map<String, Queue<DateTime>> _actionHistory = {};

  /// 특정 액션에 대한 Rate Limit 확인
  /// 
  /// [action] 액션 이름 (예: 'like', 'send_message')
  /// [maxActions] 최대 액션 수
  /// [windowSeconds] 시간 윈도우 (초)
  /// 
  /// Returns true if action is allowed, false otherwise
  static bool isAllowed(
    String action,
    int maxActions,
    int windowSeconds,
  ) {
    final now = DateTime.now();
    final key = action;
    
    if (!_actionHistory.containsKey(key)) {
      _actionHistory[key] = Queue<DateTime>();
    }

    final history = _actionHistory[key]!;
    final cutoff = now.subtract(Duration(seconds: windowSeconds));

    // 오래된 기록 제거
    while (history.isNotEmpty && history.first.isBefore(cutoff)) {
      history.removeFirst();
    }

    // 제한 확인
    if (history.length >= maxActions) {
      return false;
    }

    // 액션 기록
    history.add(now);
    return true;
  }

  /// Rate Limit 초과 시 남은 시간 반환 (초)
  static int? getRemainingSeconds(
    String action,
    int maxActions,
    int windowSeconds,
  ) {
    final now = DateTime.now();
    final key = action;
    
    if (!_actionHistory.containsKey(key)) {
      return null;
    }

    final history = _actionHistory[key]!;
    if (history.isEmpty) return null;

    final cutoff = now.subtract(Duration(seconds: windowSeconds));
    final oldestAction = history.first;

    if (oldestAction.isAfter(cutoff)) {
      final remaining = windowSeconds - now.difference(oldestAction).inSeconds;
      return remaining > 0 ? remaining : null;
    }

    return null;
  }

  /// 특정 액션의 기록 초기화
  static void reset(String action) {
    _actionHistory.remove(action);
  }

  /// 모든 기록 초기화
  static void resetAll() {
    _actionHistory.clear();
  }
}

