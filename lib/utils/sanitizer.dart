/// 입력값 Sanitization 유틸리티 (XSS 방지 등)
class Sanitizer {
  /// HTML 태그 제거 및 특수문자 이스케이프
  static String sanitizeHtml(String input) {
    // HTML 태그 제거
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 특수문자 이스케이프
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    return sanitized;
  }

  /// 채팅 메시지 Sanitization (기본적인 XSS 방지)
  static String sanitizeChatMessage(String input) {
    // HTML 태그 제거
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // JavaScript 이벤트 핸들러 제거
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    
    // URL 스킴 검증 (javascript:, data: 등 위험한 스킴 제거)
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'data:', caseSensitive: false), '');
    
    // 특수문자 이스케이프 (XSS 방지)
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    return sanitized.trim();
  }

  /// 프로필 텍스트 Sanitization
  static String sanitizeProfileText(String input) {
    // HTML 태그 제거
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 연속된 공백 정리
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized.trim();
  }

  /// 이메일 형식 검증 및 정규화
  static String? normalizeEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(trimmed)) {
      return null;
    }
    
    return trimmed;
  }

  /// SQL Injection 방지 (Firestore는 NoSQL이지만 방어적 코딩)
  static String sanitizeForQuery(String input) {
    // 특수 문자 제거 (쿼리에 사용되는 문자들)
    return input.replaceAll(RegExp(r'[.$\[\]#/]'), '');
  }

  /// 파일명 Sanitization
  static String sanitizeFileName(String fileName) {
    // 위험한 문자 제거
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    
    // 연속된 점 제거
    sanitized = sanitized.replaceAll(RegExp(r'\.{2,}'), '.');
    
    // 선행/후행 점 및 공백 제거
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    
    return sanitized.isEmpty ? 'file' : sanitized;
  }
}

