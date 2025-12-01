import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

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

      return true;
    } catch (e) {
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
}

