import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/utils/sanitizer.dart';

void main() {
  group('Chat Message Sanitization Tests', () {
    test('sanitizeChatMessage removes HTML tags and escapes special chars', () {
      expect(
        Sanitizer.sanitizeChatMessage('<script>alert("XSS")</script>Hello'),
        equals('alert(&quot;XSS&quot;)Hello'),
      );
    });

    test('sanitizeChatMessage removes JavaScript URLs', () {
      expect(
        Sanitizer.sanitizeChatMessage('javascript:alert("XSS")'),
        equals('alert(&quot;XSS&quot;)'),
      );
    });

    test('sanitizeChatMessage removes event handlers', () {
      expect(
        Sanitizer.sanitizeChatMessage('<div onclick="alert(1)">Click</div>'),
        equals('Click'),
      );
    });

    test('sanitizeChatMessage preserves normal text', () {
      expect(
        Sanitizer.sanitizeChatMessage('Hello, how are you?'),
        equals('Hello, how are you?'),
      );
    });

    test('sanitizeChatMessage trims whitespace', () {
      expect(
        Sanitizer.sanitizeChatMessage('  Hello  '),
        equals('Hello'),
      );
    });
  });
}

