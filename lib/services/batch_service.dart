import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

/// 배치 작업 서비스 (성능 최적화)
class BatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _maxBatchSize = 500; // Firestore 배치 제한

  /// 여러 좋아요를 배치로 처리
  static Future<bool> batchLikeUsers(List<String> userIds) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        AppLogger.warning('배치 좋아요 실패: 로그인 필요');
        return false;
      }

      if (userIds.isEmpty) return true;

      // 배치 크기 제한 확인
      if (userIds.length > _maxBatchSize) {
        AppLogger.warning('배치 크기 초과', {
          'requested': userIds.length,
          'max': _maxBatchSize,
        });
        throw Exception('한 번에 최대 $_maxBatchSize개까지만 처리할 수 있습니다.');
      }

      final batch = _firestore.batch();
      final timestamp = DateTime.now().toIso8601String();

      for (final userId in userIds) {
        final likeRef = _firestore.collection('likes').doc();
        batch.set(likeRef, {
          'fromUserId': currentUserId,
          'toUserId': userId,
          'timestamp': timestamp,
        });
      }

      await batch.commit();
      AppLogger.info('배치 좋아요 성공', {
        'count': userIds.length,
        'userId': currentUserId,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('배치 좋아요 실패', e, stackTrace);
      return false;
    }
  }

  /// 여러 알림을 배치로 생성
  static Future<bool> batchCreateNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      if (notifications.isEmpty) return true;

      if (notifications.length > _maxBatchSize) {
        throw Exception('한 번에 최대 $_maxBatchSize개까지만 처리할 수 있습니다.');
      }

      final batch = _firestore.batch();

      for (final notification in notifications) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          ...notification,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      AppLogger.info('배치 알림 생성 성공', {'count': notifications.length});

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('배치 알림 생성 실패', e, stackTrace);
      return false;
    }
  }

  /// 여러 메시지를 읽음 처리
  static Future<bool> batchMarkMessagesAsSeen(List<String> messageIds) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      if (messageIds.isEmpty) return true;

      final batch = _firestore.batch();

      for (final messageId in messageIds) {
        final messageRef = _firestore.collection('messages').doc(messageId);
        batch.update(messageRef, {'seen': true});
      }

      await batch.commit();
      AppLogger.info('배치 메시지 읽음 처리 성공', {'count': messageIds.length});

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('배치 메시지 읽음 처리 실패', e, stackTrace);
      return false;
    }
  }
}

