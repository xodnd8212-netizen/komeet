import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../utils/validators.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'analytics_service.dart';
import 'performance_service.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'profiles';

  static Future<String?> saveProfile(UserProfile profile) async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 입력값 검증
      final nameError = Validators.name(profile.name);
      if (nameError != null) throw Exception(nameError);

      // 나이 검증 (생년월일 기반 강화 검증)
      final ageError = Validators.validateAgeWithBirthDate(
        profile.age,
        profile.birthDate,
      );
      if (ageError != null) throw Exception(ageError);

      final bioError = Validators.bio(profile.bio);
      if (bioError != null) throw Exception(bioError);

      final cityError = Validators.city(profile.city);
      if (cityError != null) throw Exception(cityError);

      final interestsError = Validators.interests(profile.interests);
      if (interestsError != null) throw Exception(interestsError);

      final photosError = Validators.photos(profile.photoUrls);
      if (photosError != null) throw Exception(photosError);

      final coordinatesError = Validators.coordinates(profile.lat, profile.lng);
      if (coordinatesError != null) {
        AppLogger.warning('위치 정보 없이 프로필 저장', {'userId': userId});
        // 위치 정보는 선택사항으로 처리
      }

      final data = profile
          .copyWith(
            id: profile.id ?? userId,
            updatedAt: DateTime.now(),
            createdAt: profile.createdAt ?? DateTime.now(),
          )
          .toMap();

      final isNewProfile =
          !(await _firestore.collection(_collection).doc(userId).get()).exists;

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(data, SetOptions(merge: true));

      AppLogger.info('프로필 저장 성공', {'userId': userId});

      // 분석 이벤트: 프로필 완성
      await AnalyticsService.logProfileCompleted(
        photoCount: profile.photoUrls.length,
        bioLength: profile.bio.length,
        interestCount: profile.interests.length,
      );

      // 성능 메트릭 추가
      PerformanceService.addMetric(
        trace,
        'photo_count',
        profile.photoUrls.length,
      );
      PerformanceService.addMetric(trace, 'bio_length', profile.bio.length);

      trace?.stop();
      return userId;
    } on FirebaseException catch (e, stackTrace) {
      PerformanceService.addAttribute(trace, 'error', 'firebase_exception');
      trace?.stop();
      AppLogger.error('프로필 저장 실패 (Firebase)', e, stackTrace);
      throw Exception('프로필 저장 실패: ${e.message}');
    } catch (e, stackTrace) {
      PerformanceService.addAttribute(trace, 'error', e.toString());
      trace?.stop();
      AppLogger.error('프로필 저장 중 오류', e, stackTrace);
      throw Exception('프로필 저장 중 오류가 발생했습니다: $e');
    }
  }

  static Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) return null;
    return getProfile(userId);
  }

  static Stream<UserProfile?> watchProfile(String userId) {
    return _firestore.collection(_collection).doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  /// 프로필 완성도 점수 계산 (0-100)
  static int calculateCompletenessScore(UserProfile profile) {
    int score = 0;

    // 사진 (최대 30점)
    final photoCount = profile.photoUrls.length;
    score += (photoCount / 6.0 * 30).clamp(0, 30).round();

    // 자기소개 (최대 25점)
    final bioLength = profile.bio.length;
    if (bioLength >= 200) {
      score += 25;
    } else if (bioLength >= 100) {
      score += 20;
    } else if (bioLength >= 50) {
      score += 15;
    } else if (bioLength >= 10) {
      score += 10;
    }

    // 관심사 (최대 20점)
    final interestCount = profile.interests.length;
    score += (interestCount / 5.0 * 20).clamp(0, 20).round();

    // 위치 정보 (최대 15점)
    if (profile.lat != null && profile.lng != null) {
      score += 15;
    }

    // 인증 여부 (최대 10점)
    if (profile.isVerified) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// 프로필 완성도가 충분한지 확인
  static bool isProfileComplete(UserProfile profile) {
    return calculateCompletenessScore(profile) >= 60;
  }

  /// 프로필 인증 상태 업데이트
  static Future<void> updateVerificationStatus(
    String userId,
    bool isVerified,
  ) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isVerified': isVerified,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      AppLogger.info('프로필 인증 상태 업데이트', {
        'userId': userId,
        'isVerified': isVerified,
      });
    } catch (e, stackTrace) {
      AppLogger.error('프로필 인증 상태 업데이트 실패', e, stackTrace);
      throw Exception('인증 상태 업데이트 실패: $e');
    }
  }

  static Future<List<UserProfile>> getNearbyProfiles({
    required double lat,
    required double lng,
    required double maxDistanceKm,
    int limit = 20,
  }) async {
    try {
      // 간단한 구현: 모든 프로필을 가져와서 클라이언트에서 필터링
      // 실제로는 GeoFirestore 같은 것을 사용하는 것이 좋습니다
      final snapshot = await _firestore
          .collection(_collection)
          .limit(limit * 2)
          .get();

      final profiles = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .where((p) => p.lat != null && p.lng != null)
          .toList();

      // 거리 계산은 클라이언트에서 (실제로는 서버에서 해야 함)
      return profiles.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
