import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'notifications.dart';
import 'user_safety_service.dart';
import 'geo.dart' as geo;

// 페이지네이션 결과를 담는 클래스
class RecommendationsResult {
  final List<UserProfile> profiles;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  RecommendationsResult({
    required this.profiles,
    this.lastDocument,
    required this.hasMore,
  });
}

class MatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _likesCollection = 'likes';
  static const String _matchesCollection = 'matches';

  static Future<bool> likeUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      // 좋아요 저장
      final likeDoc = await _firestore.collection(_likesCollection).add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 마지막 좋아요 저장 (되돌리기용)
      await _firestore.collection('users').doc(currentUserId).set({
        'lastLikeId': likeDoc.id,
        'lastLikeUserId': targetUserId,
        'lastLikeTimestamp': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // 상대방에게 좋아요 알림 저장
      await _firestore.collection('notifications').add({
        'type': 'like',
        'userId': targetUserId,
        'fromUserId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // 상대방이 나를 좋아요 했는지 확인
      final mutualLike = await _firestore
          .collection(_likesCollection)
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (mutualLike.docs.isNotEmpty) {
        // 매칭 생성
        await _createMatch(currentUserId, targetUserId);
        return true; // 매칭 성공
      }

      return false; // 단방향 좋아요
    } catch (e) {
      return false;
    }
  }

  /// 마지막 좋아요 되돌리기
  static Future<bool> undoLastLike() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final lastLikeId = data['lastLikeId'] as String?;
      final lastLikeUserId = data['lastLikeUserId'] as String?;

      if (lastLikeId == null || lastLikeUserId == null) return false;

      // 좋아요 삭제
      await _firestore.collection(_likesCollection).doc(lastLikeId).delete();

      // 마지막 좋아요 정보 삭제
      await _firestore.collection('users').doc(currentUserId).update({
        'lastLikeId': FieldValue.delete(),
        'lastLikeUserId': FieldValue.delete(),
        'lastLikeTimestamp': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 마지막 좋아요 정보 가져오기
  static Future<Map<String, String>?> getLastLikeInfo() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final lastLikeId = data['lastLikeId'] as String?;
      final lastLikeUserId = data['lastLikeUserId'] as String?;

      if (lastLikeId == null || lastLikeUserId == null) return null;

      return {
        'likeId': lastLikeId,
        'userId': lastLikeUserId,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> _createMatch(String userId1, String userId2) async {
    final participants = [userId1, userId2]..sort();
    final matchId = participants.join('_');

    await _firestore.collection(_matchesCollection).doc(matchId).set({
      'participantIds': participants,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // 양쪽 사용자에게 매칭 알림 표시
    try {
      final profile1 = await ProfileService.getProfile(userId1);
      final profile2 = await ProfileService.getProfile(userId2);
      
      if (profile1 != null && profile2 != null) {
        // 각 사용자에게 상대방 이름으로 알림 표시
        final currentUserId = AuthService.currentUser?.uid;
        if (currentUserId == userId1) {
          await NotificationService.showMatchNotification(profile2.name);
        } else if (currentUserId == userId2) {
          await NotificationService.showMatchNotification(profile1.name);
        }
      }
    } catch (e) {
      // 알림 실패는 무시
    }

    // Firestore에 알림 데이터 저장 (서버에서 푸시 알림 전송하도록)
    try {
      await _firestore.collection('notifications').add({
        'type': 'match',
        'userId': userId2,
        'fromUserId': userId1,
        'matchId': matchId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      await _firestore.collection('notifications').add({
        'type': 'match',
        'userId': userId1,
        'fromUserId': userId2,
        'matchId': matchId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      // 알림 저장 실패는 무시
    }
  }

  static Future<List<String>> getMatchedUserIds() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection(_matchesCollection)
          .where('participantIds', arrayContains: currentUserId)
          .get();

      final matchedIds = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participantIds'] ?? []);
        for (final id in participants) {
          if (id != currentUserId) {
            matchedIds.add(id);
          }
        }
      }
      return matchedIds;
    } catch (e) {
      return [];
    }
  }

  // 기존 메서드 호환성을 위한 래퍼
  static Future<List<UserProfile>> getRecommendations({
    required double lat,
    required double lng,
    required double maxDistanceKm,
    bool tokyoOnly = false,
    int limit = 20,
  }) async {
      final result = await getRecommendationsWithPagination(
        lat: lat,
        lng: lng,
        maxDistanceKm: maxDistanceKm,
        tokyoOnly: tokyoOnly,
        minAge: null,
        maxAge: null,
        genderPreference: null,
        limit: limit,
      );
    return result.profiles;
  }

  // 페이지네이션 지원 메서드
  static Future<RecommendationsResult> getRecommendationsWithPagination({
    required double lat,
    required double lng,
    required double maxDistanceKm,
    bool tokyoOnly = false,
    int? minAge,
    int? maxAge,
    String? genderPreference,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        return RecommendationsResult(profiles: [], hasMore: false);
      }

      // 이미 좋아요한 사용자 ID 가져오기
      final likesSnapshot = await _firestore
          .collection(_likesCollection)
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      final likedIds = likesSnapshot.docs
          .map((doc) => doc.data()['toUserId'] as String)
          .toSet();

      // 매칭된 사용자 ID 가져오기
      final matchedIds = await getMatchedUserIds();
      
      // 차단된 사용자 ID 가져오기
      final blockedIds = await UserSafetyService.getBlockedUserIds();
      
      final excludedIds = {...likedIds, ...matchedIds, ...blockedIds, currentUserId};

      // 프로필 가져오기 (페이지네이션 지원)
      Query query = _firestore.collection('profiles');
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final profilesSnapshot = await query
          .limit(limit * 3)
          .get();

      final allProfiles = profilesSnapshot.docs
          .where((doc) => !excludedIds.contains(doc.id))
          .map((doc) => UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((p) => p.lat != null && p.lng != null)
          .toList();

      // 필터링
      final filtered = allProfiles.where((p) {
        // 도쿄 필터
        if (tokyoOnly && p.city.toLowerCase() != 'tokyo') return false;
        
        // 나이 필터
        if (minAge != null && p.age < minAge) return false;
        if (maxAge != null && p.age > maxAge) return false;
        
        // 성별 선호도 필터
        if (genderPreference != null && genderPreference != 'any') {
          if (p.gender != genderPreference) return false;
        }
        
        // 거리 필터
        final distance = geo.haversineKm(
          geo.GeoPoint(lat, lng),
          geo.GeoPoint(p.lat!, p.lng!),
        );
        return distance <= maxDistanceKm;
      }).toList();

      // 거리순 정렬
      filtered.sort((a, b) {
        final distA = geo.haversineKm(
          geo.GeoPoint(lat, lng),
          geo.GeoPoint(a.lat!, a.lng!),
        );
        final distB = geo.haversineKm(
          geo.GeoPoint(lat, lng),
          geo.GeoPoint(b.lat!, b.lng!),
        );
        return distA.compareTo(distB);
      });

      final result = filtered.take(limit).toList();
      final hasMore = profilesSnapshot.docs.length >= limit * 3 && result.length >= limit;
      final lastDoc = hasMore && profilesSnapshot.docs.isNotEmpty 
        ? profilesSnapshot.docs.last 
        : null;

      return RecommendationsResult(
        profiles: result,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      return RecommendationsResult(
        profiles: [],
        hasMore: false,
      );
    }
  }
}
