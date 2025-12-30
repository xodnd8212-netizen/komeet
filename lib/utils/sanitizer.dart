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
  /// URL 패턴 감지
  static bool containsUrl(String text) {
    final urlPattern = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  /// 스팸 키워드 감지 (기본 리스트)
  static bool containsSpamKeywords(String text) {
    final spamKeywords = [
      // 한국어 스팸 키워드
      '광고', '홍보', '이벤트', '무료', '할인', '쿠폰', '프로모션',
      '수입', '부업', '투자', '대출', '카지노', '도박',
      // 일본어 스팸 키워드
      '宣伝', 'イベント', '無料', '割引', 'クーポン', 'プロモーション',
      '収入', '副業', '投資', 'ローン', 'カジノ', 'ギャンブル',
      // 영어 스팸 키워드
      'advertisement', 'promotion', 'free', 'discount', 'coupon',
      'income', 'investment', 'loan', 'casino', 'gambling',
      // 단축 URL 서비스
      'bit.ly', 'tinyurl', 'goo.gl', 't.co', 'short.link',
      // 의심스러운 패턴
      '클릭', '지금', '바로', 'click', 'now', 'immediately',
    ];

    final lowerText = text.toLowerCase();
    return spamKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );
  }

  /// 채팅 메시지 검증 및 필터링
  static String sanitizeChatMessage(String input, {bool allowUrls = false}) {
    // HTML 태그 제거
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // JavaScript 이벤트 핸들러 제거
    sanitized = sanitized.replaceAll(
      RegExp(r'on\w+\s*=', caseSensitive: false),
      '',
    );

    // URL 스킴 검증 (javascript:, data: 등 위험한 스킴 제거)
    sanitized = sanitized.replaceAll(
      RegExp(r'javascript:', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'data:', caseSensitive: false),
      '',
    );

    // URL 필터링 (allowUrls가 false인 경우)
    if (!allowUrls && containsUrl(sanitized)) {
      throw Exception('메시지에 링크를 포함할 수 없습니다. 안전을 위해 링크 공유는 제한됩니다.');
    }

    // 스팸 키워드 필터링
    if (containsSpamKeywords(sanitized)) {
      throw Exception('스팸으로 의심되는 메시지입니다. 다른 내용으로 작성해주세요.');
    }

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
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

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
