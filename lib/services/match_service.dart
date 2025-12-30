import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'notifications.dart';
import 'user_safety_service.dart';
import 'geo.dart' as geo;
import 'analytics_service.dart';
import 'performance_service.dart';

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
    final trace = PerformanceService.startTrace('like_user');
    try {
      trace?.start();
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        AppLogger.warning('좋아요 실패: 로그인 필요');
        trace?.stop();
        return false;
      }

      // Rate Limiting 확인 (1분에 최대 10개)
      if (!RateLimiter.isAllowed('like', 10, 60)) {
        final remaining = RateLimiter.getRemainingSeconds('like', 10, 60);
        AppLogger.warning('좋아요 Rate Limit 초과', {
          'userId': currentUserId,
          'remainingSeconds': remaining,
        });
        throw Exception(
          '너무 빠르게 좋아요를 보내고 있습니다. ${remaining != null ? '$remaining초 후 다시 시도해주세요.' : '잠시 후 다시 시도해주세요.'}',
        );
      }

      // 좋아요 저장
      final likeDoc = await _firestore.collection(_likesCollection).add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      AppLogger.info('좋아요 전송', {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
      });

      // 분석 이벤트: 좋아요 전송
      await AnalyticsService.logLikeSent(targetUserId);

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
        PerformanceService.addAttribute(trace, 'result', 'match');
        trace?.stop();
        return true; // 매칭 성공
      }

      PerformanceService.addAttribute(trace, 'result', 'like_only');
      trace?.stop();
      return false; // 단방향 좋아요
    } catch (e) {
      PerformanceService.addAttribute(trace, 'error', e.toString());
      trace?.stop();
      return false;
    }
  }

  /// 마지막 좋아요 되돌리기
  static Future<bool> undoLastLike() async {
    try {
      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) return false;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
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

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final lastLikeId = data['lastLikeId'] as String?;
      final lastLikeUserId = data['lastLikeUserId'] as String?;

      if (lastLikeId == null || lastLikeUserId == null) return null;

      return {'likeId': lastLikeId, 'userId': lastLikeUserId};
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

    // 분석 이벤트: 매칭 성공
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId != null) {
      final matchedUserId = currentUserId == userId1 ? userId2 : userId1;
      await AnalyticsService.logMatchCreated(
        matchedUserId: matchedUserId,
        matchType: 'mutual_like',
      );
    }

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
    final trace = PerformanceService.startTrace('get_recommendations');
    try {
      trace?.start();
      PerformanceService.addMetric(trace, 'limit', limit);
      PerformanceService.addAttribute(
        trace,
        'tokyo_only',
        tokyoOnly.toString(),
      );

      final currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        trace?.stop();
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

      final excludedIds = {
        ...likedIds,
        ...matchedIds,
        ...blockedIds,
        currentUserId,
      };

      // 프로필 가져오기 (페이지네이션 지원)
      Query query = _firestore.collection('profiles');

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final profilesSnapshot = await query.limit(limit * 3).get();

      final allProfiles = profilesSnapshot.docs
          .where((doc) => !excludedIds.contains(doc.id))
          .map(
            (doc) =>
                UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .where((p) => p.lat != null && p.lng != null)
          .toList();

      // 현재 사용자 프로필 가져오기 (국가 판별용)
      final currentProfile = await ProfileService.getCurrentUserProfile();
      final isCurrentUserKorean =
          currentProfile?.city.contains('서울') == true ||
          currentProfile?.city.contains('Seoul') == true ||
          currentProfile?.city.contains('한국') == true ||
          currentProfile?.city.contains('Korea') == true;

      // 필터링 및 스코어링
      final scoredProfiles = allProfiles
          .map((p) {
            // 도쿄 필터
            if (tokyoOnly && p.city.toLowerCase() != 'tokyo') return null;

            // 나이 필터
            if (minAge != null && p.age < minAge) return null;
            if (maxAge != null && p.age > maxAge) return null;

            // 성별 선호도 필터
            if (genderPreference != null && genderPreference != 'any') {
              if (p.gender != genderPreference) return null;
            }

            // 거리 계산
            final distance = geo.haversineKm(
              geo.GeoPoint(lat, lng),
              geo.GeoPoint(p.lat!, p.lng!),
            );

            // 국가 간 매칭 특별 처리 (일본-한국 간 500km 허용)
            final isTargetKorean =
                p.city.contains('서울') == true ||
                p.city.contains('Seoul') == true ||
                p.city.contains('한국') == true ||
                p.city.contains('Korea') == true;
            final isTargetJapanese =
                p.city.contains('Tokyo') == true ||
                p.city.contains('도쿄') == true ||
                p.city.contains('일본') == true ||
                p.city.contains('Japan') == true;

            // 국가 간 매칭인 경우 거리 제한 완화
            final effectiveMaxDistance =
                (isCurrentUserKorean && isTargetJapanese) ||
                    (isCurrentUserKorean == false && isTargetKorean)
                ? 500.0 // 일본-한국 간 매칭은 500km 허용
                : maxDistanceKm;

            if (distance > effectiveMaxDistance) return null;

            // 스마트 스코어 계산 (프로필 완성도, 인증 여부, 거리 등 고려)
            double score = 100.0;

            // 프로필 완성도 점수 (사진 개수, 소개 길이, 관심사 개수)
            final photoScore =
                (p.photoUrls.length / 6.0).clamp(0.0, 1.0) * 30.0; // 최대 30점
            final bioScore =
                (p.bio.length / 200.0).clamp(0.0, 1.0) * 20.0; // 최대 20점
            final interestScore =
                (p.interests.length / 5.0).clamp(0.0, 1.0) * 20.0; // 최대 20점

            // 인증 여부 보너스
            final verifiedBonus = p.isVerified ? 30.0 : 0.0;

            // 거리 점수 (가까울수록 높은 점수, 최대 30점)
            final distanceScore =
                (1.0 - (distance / effectiveMaxDistance).clamp(0.0, 1.0)) *
                30.0;

            // 국가 간 매칭 보너스 (다양성 증가)
            final crossCountryBonus =
                (isCurrentUserKorean && isTargetJapanese) ||
                    (isCurrentUserKorean == false && isTargetKorean)
                ? 10.0
                : 0.0;

            score =
                photoScore +
                bioScore +
                interestScore +
                verifiedBonus +
                distanceScore +
                crossCountryBonus;

            return MapEntry(p, score);
          })
          .where((entry) => entry != null)
          .cast<MapEntry<UserProfile, double>>()
          .toList();

      // 스코어순 정렬 (높은 점수 우선)
      scoredProfiles.sort((a, b) => b.value.compareTo(a.value));

      final filtered = scoredProfiles.map((e) => e.key).toList();

      final result = filtered.take(limit).toList();
      final hasMore =
          profilesSnapshot.docs.length >= limit * 3 && result.length >= limit;
      final lastDoc = hasMore && profilesSnapshot.docs.isNotEmpty
          ? profilesSnapshot.docs.last
          : null;

      PerformanceService.addMetric(trace, 'result_count', result.length);
      trace?.stop();

      return RecommendationsResult(
        profiles: result,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      PerformanceService.addAttribute(trace, 'error', e.toString());
      trace?.stop();
      return RecommendationsResult(profiles: [], hasMore: false);
    }
  }
}
