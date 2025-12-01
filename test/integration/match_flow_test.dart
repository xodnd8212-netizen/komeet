import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/models/profile.dart';
import 'package:komeet/utils/validators.dart';

void main() {
  group('Match Flow Integration Tests', () {
    test('Complete profile validation flow', () {
      // 1. 프로필 생성
      final profile = UserProfile(
        name: 'Test User',
        age: 25,
        gender: 'male',
        city: 'Seoul',
        bio: 'This is a test bio that is long enough',
        interests: ['Music', 'Sports'],
        lat: 37.5665,
        lng: 126.9780,
        photoUrls: ['url1', 'url2'],
      );

      // 2. 검증
      expect(Validators.name(profile.name), isNull);
      expect(Validators.age(profile.age), isNull);
      expect(Validators.bio(profile.bio), isNull);
      expect(Validators.city(profile.city), isNull);
      expect(Validators.interests(profile.interests), isNull);
      expect(Validators.photos(profile.photoUrls), isNull);
      expect(Validators.coordinates(profile.lat, profile.lng), isNull);

      // 3. 직렬화/역직렬화
      final map = profile.toMap();
      final restored = UserProfile.fromMap('test-id', map);

      expect(restored.name, equals(profile.name));
      expect(restored.age, equals(profile.age));
      expect(restored.gender, equals(profile.gender));
    });

    test('Invalid profile should fail validation', () {
      // 나이가 너무 어린 경우
      expect(Validators.age(17), isNotNull);
      
      // 이름이 너무 짧은 경우
      expect(Validators.name('A'), isNotNull);
      
      // 자기소개가 너무 짧은 경우
      expect(Validators.bio('Short'), isNotNull);
      
      // 관심사가 없는 경우
      expect(Validators.interests([]), isNotNull);
      
      // 사진이 없는 경우
      expect(Validators.photos([]), isNotNull);
    });
  });
}

