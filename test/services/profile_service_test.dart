import 'package:flutter_test/flutter_test.dart';
import 'package:komeet/models/profile.dart';
import 'package:komeet/utils/validators.dart';

void main() {
  group('ProfileService Tests', () {
    test('Validators - name validation', () {
      expect(Validators.name(null), isNotNull);
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull); // 너무 짧음
      expect(Validators.name('Valid Name'), isNull);
      expect(Validators.name('A' * 51), isNotNull); // 너무 김
    });

    test('Validators - age validation', () {
      expect(Validators.age(null), isNotNull);
      expect(Validators.age(17), isNotNull); // 18세 미만
      expect(Validators.age(18), isNull);
      expect(Validators.age(25), isNull);
      expect(Validators.age(101), isNotNull); // 너무 많음
    });

    test('Validators - bio validation', () {
      expect(Validators.bio(null), isNotNull);
      expect(Validators.bio(''), isNotNull);
      expect(Validators.bio('Short'), isNotNull); // 너무 짧음
      expect(Validators.bio('This is a valid bio that is long enough'), isNull);
      expect(Validators.bio('A' * 501), isNotNull); // 너무 김
    });

    test('Validators - city validation', () {
      expect(Validators.city(null), isNotNull);
      expect(Validators.city(''), isNotNull);
      expect(Validators.city('Seoul'), isNull);
      expect(Validators.city('A' * 101), isNotNull); // 너무 김
    });

    test('Validators - interests validation', () {
      expect(Validators.interests(null), isNotNull);
      expect(Validators.interests([]), isNotNull); // 빈 리스트
      expect(Validators.interests(['Music']), isNull);
      expect(Validators.interests(['A', 'B', 'C', 'D', 'E', 'F']), isNotNull); // 6개 초과
    });

    test('Validators - photos validation', () {
      expect(Validators.photos(null), isNotNull);
      expect(Validators.photos([]), isNotNull); // 빈 리스트
      expect(Validators.photos(['url1']), isNull);
      expect(Validators.photos(['url1', 'url2', 'url3', 'url4', 'url5', 'url6', 'url7']), isNotNull); // 7개 초과
    });

    test('UserProfile - fromMap and toMap', () {
      final profile = UserProfile(
        name: 'Test User',
        age: 25,
        gender: 'male',
        city: 'Seoul',
        bio: 'Test bio',
        interests: ['Music', 'Sports'],
        lat: 37.5665,
        lng: 126.9780,
        photoUrls: ['url1', 'url2'],
        maxDistanceKm: 50.0,
        isVerified: true,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap('test-id', map);

      expect(restored.name, equals(profile.name));
      expect(restored.age, equals(profile.age));
      expect(restored.gender, equals(profile.gender));
      expect(restored.city, equals(profile.city));
      expect(restored.bio, equals(profile.bio));
      expect(restored.interests, equals(profile.interests));
      expect(restored.lat, equals(profile.lat));
      expect(restored.lng, equals(profile.lng));
      expect(restored.photoUrls, equals(profile.photoUrls));
      expect(restored.maxDistanceKm, equals(profile.maxDistanceKm));
      expect(restored.isVerified, equals(profile.isVerified));
    });

    test('UserProfile - copyWith', () {
      final original = UserProfile(
        name: 'Original',
        age: 25,
        city: 'Seoul',
        bio: 'Original bio',
      );

      final updated = original.copyWith(
        name: 'Updated',
        age: 30,
      );

      expect(updated.name, equals('Updated'));
      expect(updated.age, equals(30));
      expect(updated.city, equals(original.city)); // 변경되지 않음
      expect(updated.bio, equals(original.bio)); // 변경되지 않음
    });
  });
}

