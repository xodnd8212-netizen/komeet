import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'analytics_service.dart';

/// 프로필 인증 서비스
class VerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _verificationsCollection = 'verifications';

  /// 인증 요청 제출 (관리자 검토 대기)
  static Future<bool> submitVerificationRequest({
    required String photoUrl, // 신분증 또는 인증 사진 URL
    String? additionalInfo,
  }) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection(_verificationsCollection).add({
        'userId': currentUserId,
        'photoUrl': photoUrl,
        'additionalInfo': additionalInfo ?? '',
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });

      AppLogger.info('인증 요청 제출', {'userId': currentUserId});

      // 분석 이벤트: 인증 요청 제출
      await AnalyticsService.logVerificationRequested(currentUserId);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('인증 요청 제출 실패', e, stackTrace);
      return false;
    }
  }

  /// 인증 상태 확인
  static Future<String?> getVerificationStatus() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return null;

      final snapshot = await _firestore
          .collection(_verificationsCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.data()['status'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 인증 여부 확인
  static Future<bool> isVerified() async {
    try {
      final status = await getVerificationStatus();
      return status == 'approved';
    } catch (e) {
      return false;
    }
  }

  /// 인증 요청 승인 (관리자 전용)
  static Future<bool> approveVerification({
    required String verificationId,
    required String reviewedBy,
  }) async {
    try {
      final verificationRef = _firestore
          .collection(_verificationsCollection)
          .doc(verificationId);

      final verificationDoc = await verificationRef.get();
      if (!verificationDoc.exists) {
        throw Exception('인증 요청을 찾을 수 없습니다.');
      }

      final verificationData = verificationDoc.data()!;
      final userId = verificationData['userId'] as String;

      // 인증 요청 상태 업데이트
      await verificationRef.update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
      });

      // 프로필에 인증 상태 업데이트
      await ProfileService.updateVerificationStatus(userId, true);

      // 분석 이벤트: 인증 완료
      await AnalyticsService.logProfileVerified(userId);

      AppLogger.info('인증 요청 승인', {
        'verificationId': verificationId,
        'userId': userId,
        'reviewedBy': reviewedBy,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('인증 요청 승인 실패', e, stackTrace);
      return false;
    }
  }

  /// 인증 요청 거부 (관리자 전용)
  static Future<bool> rejectVerification({
    required String verificationId,
    required String reviewedBy,
    String? reason,
  }) async {
    try {
      final verificationRef = _firestore
          .collection(_verificationsCollection)
          .doc(verificationId);

      await verificationRef.update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
        'rejectionReason': reason ?? '',
      });

      AppLogger.info('인증 요청 거부', {
        'verificationId': verificationId,
        'reviewedBy': reviewedBy,
        'reason': reason,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('인증 요청 거부 실패', e, stackTrace);
      return false;
    }
  }

  /// 대기 중인 인증 요청 목록 가져오기 (관리자 전용)
  static Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      final snapshot = await _firestore
          .collection(_verificationsCollection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }
}
