import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// 사용자 안전 관련 기능 (차단, 신고, 언매치)
class UserSafetyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _blocksCollection = 'blocks';
  static const String _reportsCollection = 'reports';

  /// 사용자 차단
  static Future<bool> blockUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 차단 정보 저장
      await _firestore.collection(_blocksCollection).add({
        'blockerId': currentUserId,
        'blockedId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 매칭이 있다면 언매치 처리
      await unmatchUser(targetUserId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 사용자 차단 해제
  static Future<bool> unblockUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final snapshot = await _firestore
          .collection(_blocksCollection)
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      await snapshot.docs.first.reference.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 차단된 사용자 목록 가져오기
  static Future<List<String>> getBlockedUserIds() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection(_blocksCollection)
          .where('blockerId', isEqualTo: currentUserId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['blockedId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 사용자가 차단되었는지 확인
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 내가 차단한 사용자인지 확인
      final blockedByMe = await _firestore
          .collection(_blocksCollection)
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: userId)
          .limit(1)
          .get();

      if (blockedByMe.docs.isNotEmpty) return true;

      // 상대방이 나를 차단했는지 확인
      final blockedByOther = await _firestore
          .collection(_blocksCollection)
          .where('blockerId', isEqualTo: userId)
          .where('blockedId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return blockedByOther.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 사용자 신고
  static Future<bool> reportUser({
    required String targetUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection(_reportsCollection).add({
        'reporterId': currentUserId,
        'reportedId': targetUserId,
        'reason': reason,
        'description': description ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 매칭 해제 (언매치)
  static Future<bool> unmatchUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 매칭 문서 찾기
      final participants = [currentUserId, targetUserId]..sort();
      final matchId = participants.join('_');

      final matchDoc = await _firestore
          .collection('matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) return false;

      // 매칭 문서에 unmatchBy 필드 추가 (언매치한 사용자 기록)
      await matchDoc.reference.update({
        'unmatchedBy': currentUserId,
        'unmatchedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });

      // 채팅방 비활성화
      final chatRoomId = matchId; // matchId와 동일하게 사용
      final chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        await chatRoomDoc.reference.update({
          'isActive': false,
          'unmatchedBy': currentUserId,
          'unmatchedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 차단된 사용자 필터링 (추천 목록에서 제외)
  static Future<List<String>> filterBlockedUsers(List<String> userIds) async {
    try {
      final blockedIds = await getBlockedUserIds();
      return userIds.where((id) => !blockedIds.contains(id)).toList();
    } catch (e) {
      return userIds;
    }
  }
}

