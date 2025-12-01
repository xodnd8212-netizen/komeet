import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/utils/rate_limiter.dart';

void main() {
  group('RateLimiter Tests', () {
    setUp(() {
      RateLimiter.resetAll();
    });

    test('RateLimiter - basic functionality', () {
      expect(RateLimiter.isAllowed('test', 5, 60), isTrue);
      expect(RateLimiter.isAllowed('test', 5, 60), isTrue);
      expect(RateLimiter.isAllowed('test', 5, 60), isTrue);
      expect(RateLimiter.isAllowed('test', 5, 60), isTrue);
      expect(RateLimiter.isAllowed('test', 5, 60), isTrue);
      expect(RateLimiter.isAllowed('test', 5, 60), isFalse); // 제한 초과
    });

    test('RateLimiter - different actions', () {
      expect(RateLimiter.isAllowed('action1', 3, 60), isTrue);
      expect(RateLimiter.isAllowed('action2', 3, 60), isTrue);
      expect(RateLimiter.isAllowed('action1', 3, 60), isTrue);
      expect(RateLimiter.isAllowed('action2', 3, 60), isTrue);
      // 각 액션은 독립적으로 관리됨
      expect(RateLimiter.isAllowed('action1', 3, 60), isTrue);
      expect(RateLimiter.isAllowed('action2', 3, 60), isTrue);
    });

    test('RateLimiter - reset functionality', () {
      RateLimiter.isAllowed('test', 3, 60);
      RateLimiter.isAllowed('test', 3, 60);
      RateLimiter.isAllowed('test', 3, 60);
      expect(RateLimiter.isAllowed('test', 3, 60), isFalse);
      
      RateLimiter.reset('test');
      expect(RateLimiter.isAllowed('test', 3, 60), isTrue);
    });

    test('RateLimiter - getRemainingSeconds', () {
      RateLimiter.isAllowed('test', 3, 60);
      final remaining = RateLimiter.getRemainingSeconds('test', 3, 60);
      expect(remaining, isNotNull);
      expect(remaining! > 0, isTrue);
      expect(remaining <= 60, isTrue);
    });
  });
}

