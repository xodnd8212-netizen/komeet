import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// 프리미엄 기능 서비스 (부스트, 슈퍼라이크 등)
class PremiumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 부스트 활성화 (30분간 프로필 상단 노출)
  static Future<bool> activateBoost() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final boostEndTime = DateTime.now().add(const Duration(minutes: 30));

      await _firestore.collection('users').doc(currentUserId).set({
        'boostActive': true,
        'boostEndTime': boostEndTime.toIso8601String(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 부스트 활성화 여부 확인
  static Future<bool> isBoostActive() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final boostActive = data['boostActive'] as bool? ?? false;
      if (!boostActive) return false;

      final boostEndTimeStr = data['boostEndTime'] as String?;
      if (boostEndTimeStr == null) return false;

      final boostEndTime = DateTime.parse(boostEndTimeStr);
      if (DateTime.now().isAfter(boostEndTime)) {
        // 부스트 시간 만료
        await _firestore.collection('users').doc(currentUserId).update({
          'boostActive': false,
        });
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 슈퍼라이크 전송
  static Future<bool> sendSuperLike(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 슈퍼라이크 기록
      await _firestore.collection('superLikes').add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 사용자의 슈퍼라이크 사용 횟수 감소 (필요시)
      await _firestore.collection('users').doc(currentUserId).set({
        'superLikeCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 슈퍼라이크 사용 가능 여부 확인
  static Future<bool> canUseSuperLike() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final superLikeCount = userDoc.data()?['superLikeCount'] as int? ?? 0;
      return superLikeCount > 0;
    } catch (e) {
      return false;
    }
  }

  /// 슈퍼라이크 남은 개수 가져오기
  static Future<int> getSuperLikeCount() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return 0;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return 0;

      return userDoc.data()?['superLikeCount'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

