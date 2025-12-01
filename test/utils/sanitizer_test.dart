import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/utils/sanitizer.dart';

void main() {
  group('Sanitizer Tests', () {
    test('sanitizeHtml - removes HTML tags and escapes', () {
      final result = Sanitizer.sanitizeHtml('<script>alert("XSS")</script>Hello');
      // HTML 태그가 제거되고 특수문자가 이스케이프됨
      expect(result, contains('Hello'));
      expect(result, isNot(contains('<script>')));
      expect(result, isNot(contains('</script>')));
    });

    test('sanitizeChatMessage - removes dangerous content', () {
      final result1 = Sanitizer.sanitizeChatMessage('<script>alert("XSS")</script>');
      expect(result1, isNot(contains('<script>')));
      expect(result1, contains('alert'));
      
      final result2 = Sanitizer.sanitizeChatMessage('javascript:alert("XSS")');
      expect(result2, isNot(contains('javascript:')));
      expect(result2, contains('alert'));
    });

    test('sanitizeProfileText - cleans whitespace', () {
      expect(
        Sanitizer.sanitizeProfileText('Hello    World'),
        equals('Hello World'),
      );
      
      expect(
        Sanitizer.sanitizeProfileText('  Trimmed  '),
        equals('Trimmed'),
      );
    });

    test('normalizeEmail - validates and normalizes', () {
      expect(Sanitizer.normalizeEmail('TEST@EXAMPLE.COM'), equals('test@example.com'));
      expect(Sanitizer.normalizeEmail('  test@example.com  '), equals('test@example.com'));
      expect(Sanitizer.normalizeEmail('invalid-email'), isNull);
      expect(Sanitizer.normalizeEmail('test@'), isNull);
    });

    test('sanitizeFileName - removes dangerous characters', () {
      expect(
        Sanitizer.sanitizeFileName('file<>:"/\\|?*name.txt'),
        equals('filename.txt'),
      );
      
      expect(
        Sanitizer.sanitizeFileName('../../../etc/passwd'),
        equals('etcpasswd'),
      );
    });
  });
}

