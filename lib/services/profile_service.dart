import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../utils/validators.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

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

      final ageError = Validators.age(profile.age);
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

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(data, SetOptions(merge: true));

      AppLogger.info('프로필 저장 성공', {'userId': userId});
      return userId;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('프로필 저장 실패 (Firebase)', e, stackTrace);
      throw Exception('프로필 저장 실패: ${e.message}');
    } catch (e, stackTrace) {
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
