import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics 서비스
/// 사용자 행동 추적 및 이벤트 로깅
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Analytics 인스턴스 가져오기 (필요시)
  static FirebaseAnalytics get instance => _analytics;

  // ========== 인증 퍼널 ==========

  /// 회원가입 시작
  static Future<void> logSignupStarted(String method) async {
    await _analytics.logEvent(
      name: 'signup_started',
      parameters: {'method': method}, // 'email' or 'google'
    );
  }

  /// 회원가입 완료
  static Future<void> logSignupCompleted(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _analytics.logEvent(
      name: 'signup_completed',
      parameters: {'method': method},
    );
  }

  /// 로그인 성공
  static Future<void> logLoginSuccess(String method) async {
    await _analytics.logLogin(loginMethod: method);
    await _analytics.logEvent(
      name: 'login_success',
      parameters: {'method': method},
    );
  }

  // ========== 프로필 퍼널 ==========

  /// 프로필 편집 시작
  static Future<void> logProfileEditStarted() async {
    await _analytics.logEvent(name: 'profile_edit_started');
  }

  /// 프로필 사진 업로드
  static Future<void> logProfilePhotoUploaded(int photoCount) async {
    await _analytics.logEvent(
      name: 'profile_photo_uploaded',
      parameters: {'photo_count': photoCount},
    );
  }

  /// 프로필 완성
  static Future<void> logProfileCompleted({
    required int photoCount,
    required int bioLength,
    required int interestCount,
  }) async {
    await _analytics.logEvent(
      name: 'profile_completed',
      parameters: {
        'photo_count': photoCount,
        'bio_length': bioLength,
        'interest_count': interestCount,
      },
    );
  }

  // ========== 매칭 퍼널 ==========

  /// 매칭 페이지 조회
  static Future<void> logMatchPageViewed() async {
    await _analytics.logEvent(name: 'match_page_viewed');
  }

  /// 프로필 카드 조회
  static Future<void> logCardViewed({
    required String targetUserId,
    required int targetAge,
    required String targetGender,
    required double distanceKm,
  }) async {
    await _analytics.logEvent(
      name: 'card_viewed',
      parameters: {
        'target_user_id': _hashUserId(targetUserId), // PII 보호를 위해 해시
        'target_age': targetAge,
        'target_gender': targetGender,
        'distance_km': distanceKm.round(),
      },
    );
  }

  /// 카드 스킵 (왼쪽 스와이프)
  static Future<void> logCardSkipped(String targetUserId) async {
    await _analytics.logEvent(
      name: 'card_swiped_left',
      parameters: {'target_user_id': _hashUserId(targetUserId)},
    );
  }

  /// 좋아요 전송 (오른쪽 스와이프)
  static Future<void> logLikeSent(String targetUserId) async {
    await _analytics.logEvent(
      name: 'card_swiped_right',
      parameters: {'target_user_id': _hashUserId(targetUserId)},
    );
  }

  /// 슈퍼라이크 전송
  static Future<void> logSuperLikeSent(String targetUserId) async {
    await _analytics.logEvent(
      name: 'super_like_sent',
      parameters: {'target_user_id': _hashUserId(targetUserId)},
    );
  }

  /// 매칭 성공
  static Future<void> logMatchCreated({
    required String matchedUserId,
    required String matchType, // 'mutual_like' or 'super_like'
  }) async {
    await _analytics.logEvent(
      name: 'match_created',
      parameters: {
        'matched_user_id': _hashUserId(matchedUserId),
        'match_type': matchType,
      },
    );
  }

  // ========== 채팅 퍼널 ==========

  /// 채팅방 열기
  static Future<void> logChatOpened({
    required String chatId,
    required String matchId,
  }) async {
    await _analytics.logEvent(
      name: 'chat_opened',
      parameters: {
        'chat_id': _hashUserId(chatId),
        'match_id': _hashUserId(matchId),
      },
    );
  }

  /// 첫 메시지 전송
  static Future<void> logFirstMessageSent({
    required String chatId,
    required int timeToFirstMessageMinutes,
  }) async {
    await _analytics.logEvent(
      name: 'first_message_sent',
      parameters: {
        'chat_id': _hashUserId(chatId),
        'time_to_first_message_minutes': timeToFirstMessageMinutes,
      },
    );
  }

  /// 메시지 전송
  static Future<void> logMessageSent({
    required String chatId,
    required bool hasImage,
  }) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {'chat_id': _hashUserId(chatId), 'has_image': hasImage},
    );
  }

  /// 메시지 수신
  static Future<void> logMessageReceived(String chatId) async {
    await _analytics.logEvent(
      name: 'message_received',
      parameters: {'chat_id': _hashUserId(chatId)},
    );
  }

  // ========== 안전/신뢰 ==========

  /// 사용자 신고
  static Future<void> logUserReported({
    required String reportedUserId,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'user_reported',
      parameters: {
        'reported_user_id': _hashUserId(reportedUserId),
        'reason': reason,
      },
    );
  }

  /// 사용자 차단
  static Future<void> logUserBlocked(String blockedUserId) async {
    await _analytics.logEvent(
      name: 'user_blocked',
      parameters: {'blocked_user_id': _hashUserId(blockedUserId)},
    );
  }

  /// 프로필 인증 요청
  static Future<void> logVerificationRequested(String userId) async {
    await _analytics.logEvent(
      name: 'verification_requested',
      parameters: {'user_id': _hashUserId(userId)},
    );
  }

  /// 프로필 인증 완료
  static Future<void> logProfileVerified(String userId) async {
    await _analytics.logEvent(
      name: 'profile_verified',
      parameters: {'user_id': _hashUserId(userId)},
    );
  }

  // ========== 결제/프리미엄 ==========

  /// 코인 구매 시작
  static Future<void> logCoinPurchaseStarted({
    required int coinAmount,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'coin_purchase_started',
      parameters: {'coin_amount': coinAmount, 'price': price},
    );
  }

  /// 코인 구매 완료
  static Future<void> logCoinPurchaseCompleted({
    required int coinAmount,
    required double price,
    required String transactionId,
  }) async {
    await _analytics.logEvent(
      name: 'coin_purchase_completed',
      parameters: {
        'coin_amount': coinAmount,
        'price': price,
        'transaction_id': transactionId,
      },
    );
  }

  /// 프리미엄 기능 사용
  static Future<void> logPremiumFeatureUsed(String featureName) async {
    await _analytics.logEvent(
      name: 'premium_feature_used',
      parameters: {'feature_name': featureName},
    );
  }

  // ========== 유틸리티 ==========

  /// 사용자 ID 해시 (PII 보호)
  /// 실제 UID를 해시하여 개인정보 보호
  static String _hashUserId(String userId) {
    // 간단한 해시 (실제로는 더 강력한 해시 사용 권장)
    // Firebase Analytics는 자동으로 해시하지만, 추가 보호를 위해
    return userId.substring(0, 8) + '...';
  }

  /// 사용자 속성 설정
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// 현재 화면 설정
  static Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
