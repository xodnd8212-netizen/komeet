import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/utils/validators.dart';
import 'package:komeet/utils/sanitizer.dart';

void main() {
  group('Auth Validators Tests', () {
    test('email validation', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name+tag@example.co.uk'), isNull);
    });

    test('password validation', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull); // 6자 미만
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('password123'), isNull);
    });
  });

  group('Email Sanitizer Tests', () {
    test('normalizeEmail', () {
      expect(Sanitizer.normalizeEmail('TEST@EXAMPLE.COM'), equals('test@example.com'));
      expect(Sanitizer.normalizeEmail('  test@example.com  '), equals('test@example.com'));
      expect(Sanitizer.normalizeEmail('invalid'), isNull);
      expect(Sanitizer.normalizeEmail('test@'), isNull);
      expect(Sanitizer.normalizeEmail('@example.com'), isNull);
    });
  });
}

