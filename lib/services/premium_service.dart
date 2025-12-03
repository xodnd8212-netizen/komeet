import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
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

      AppLogger.info('부스트 활성화', {
        'userId': currentUserId,
        'endTime': boostEndTime.toIso8601String(),
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('부스트 활성화 실패', e, stackTrace);
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

      AppLogger.info('슈퍼라이크 전송', {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('슈퍼라이크 전송 실패', e, stackTrace);
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

  /// 부스트 상태 가져오기 (남은 시간 포함)
  static Future<Map<String, dynamic>?> getBoostStatus() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final boostActive = data['boostActive'] as bool? ?? false;
      if (!boostActive) return {'active': false};

      final boostEndTimeStr = data['boostEndTime'] as String?;
      if (boostEndTimeStr == null) return {'active': false};

      final boostEndTime = DateTime.parse(boostEndTimeStr);
      final now = DateTime.now();
      
      if (now.isAfter(boostEndTime)) {
        // 부스트 시간 만료
        await _firestore.collection('users').doc(currentUserId).update({
          'boostActive': false,
        });
        return {'active': false};
      }

      final remaining = boostEndTime.difference(now);
      return {
        'active': true,
        'endTime': boostEndTime,
        'remainingMinutes': remaining.inMinutes,
        'remainingSeconds': remaining.inSeconds,
      };
    } catch (e) {
      return null;
    }
  }

  /// 부스트 사용 가능 여부 확인 (코인 잔액 확인)
  static Future<bool> canBoost() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 이미 활성화된 부스트가 있는지 확인
      final status = await getBoostStatus();
      if (status?['active'] == true) return false;

      // 코인 잔액 확인 (부스트 비용: 100 코인)
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final coinBalance = userDoc.data()?['coinBalance'] as int? ?? 0;
      return coinBalance >= 100;
    } catch (e) {
      return false;
    }
  }

  /// 부스트 사용 (코인 차감)
  static Future<bool> useBoost() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 코인 잔액 확인 및 차감
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final coinBalance = userDoc.data()?['coinBalance'] as int? ?? 0;
      if (coinBalance < 100) {
        throw Exception('부스트를 사용하기에 코인이 부족합니다. (필요: 100 코인)');
      }

      // 코인 차감 및 부스트 활성화
      final boostEndTime = DateTime.now().add(const Duration(minutes: 30));
      await _firestore.collection('users').doc(currentUserId).update({
        'coinBalance': FieldValue.increment(-100),
        'boostActive': true,
        'boostEndTime': boostEndTime.toIso8601String(),
      });

      AppLogger.info('부스트 사용', {
        'userId': currentUserId,
        'endTime': boostEndTime.toIso8601String(),
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('부스트 사용 실패', e, stackTrace);
      return false;
    }
  }
}

