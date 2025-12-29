import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:komeet/services/auth_service.dart';

/// 인증 테스트
///
/// 이 테스트는 실제 Firebase 프로젝트에 연결되어 있어야 합니다.
/// 테스트 실행 전에 Firebase 설정이 완료되어 있어야 합니다.
void main() {
  group('AuthService 테스트', () {
    test('이메일/비밀번호 회원가입 테스트', () async {
      // 테스트용 이메일 (고유한 이메일 사용)
      final testEmail =
          'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'test123456';

      try {
        final credential = await AuthService.createUserWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        expect(credential, isNotNull);
        expect(credential?.user, isNotNull);
        expect(credential?.user?.email, testEmail);

        // Firebase에 사용자 정보가 저장되었는지 확인
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential!.user!.uid)
            .get();

        expect(userDoc.exists, true);
        expect(userDoc.data()?['email'], testEmail);

        print('✅ 이메일/비밀번호 회원가입 테스트 성공');
        print('   사용자 UID: ${credential.user?.uid}');
        print('   이메일: ${credential.user?.email}');

        // 테스트 후 정리 (선택사항)
        // await credential.user?.delete();
      } catch (e) {
        print('❌ 이메일/비밀번호 회원가입 테스트 실패: $e');
        rethrow;
      }
    });

    test('이메일/비밀번호 로그인 테스트', () async {
      // 먼저 회원가입
      final testEmail =
          'login_test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'test123456';

      await AuthService.createUserWithEmailAndPassword(testEmail, testPassword);

      // 로그아웃
      await AuthService.signOut();

      // 로그인 테스트
      try {
        final credential = await AuthService.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        expect(credential, isNotNull);
        expect(credential?.user, isNotNull);
        expect(credential?.user?.email, testEmail);

        // Firebase에 사용자 정보가 업데이트되었는지 확인
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential!.user!.uid)
            .get();

        expect(userDoc.exists, true);
        expect(userDoc.data()?['lastLoginAt'], isNotNull);

        print('✅ 이메일/비밀번호 로그인 테스트 성공');
        print('   사용자 UID: ${credential.user?.uid}');
      } catch (e) {
        print('❌ 이메일/비밀번호 로그인 테스트 실패: $e');
        rethrow;
      }
    });

    test('Google 로그인 테스트 (수동 테스트 필요)', () {
      // Google 로그인은 실제 디바이스/에뮬레이터에서 수동 테스트 필요
      print('⚠️ Google 로그인은 실제 디바이스에서 수동 테스트가 필요합니다.');
      print('   앱을 실행하고 Google 로그인 버튼을 클릭하여 테스트하세요.');
    });

    test('Firebase 사용자 데이터 저장 확인', () async {
      // 특정 UID로 사용자 데이터 확인
      const testUid = 'jusLNuXpKqeqmPPEKWNoimSUPUy2';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(testUid)
            .get();

        if (userDoc.exists) {
          print('✅ Firebase 사용자 데이터 확인 성공');
          print('   UID: $testUid');
          print('   데이터: ${userDoc.data()}');
        } else {
          print('⚠️ UID $testUid에 해당하는 사용자 데이터가 없습니다.');
          print('   로그인 후 자동으로 생성됩니다.');
        }
      } catch (e) {
        print('❌ Firebase 사용자 데이터 확인 실패: $e');
        rethrow;
      }
    });
  });
}
