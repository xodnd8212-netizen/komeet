import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';
import '../utils/sanitizer.dart';
import 'analytics_service.dart';
import 'error_service.dart';
import 'account_ban_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 로그인 성공 후 Firebase에 사용자 정보 저장
  static Future<void> _saveUserToFirestore(UserCredential credential) async {
    try {
      final user = credential.user;
      if (user == null) return;

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      AppLogger.info('사용자 정보 Firebase 저장 성공', {'userId': user.uid});
    } catch (e, stackTrace) {
      AppLogger.error('사용자 정보 Firebase 저장 실패', e, stackTrace);
      // 로그인은 성공했으므로 에러를 던지지 않음
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? credential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn();
        final account = await googleSignIn.signIn();
        if (account == null) return null;

        final authentication = await account.authentication;
        final googleCredential = GoogleAuthProvider.credential(
          accessToken: authentication.accessToken,
          idToken: authentication.idToken,
        );
        credential = await _auth.signInWithCredential(googleCredential);
      }

      // 재가입 방지: Google 로그인 시 정지 상태 확인
      if (credential.user != null) {
        final isBanned = await AccountBanService.isUserBanned(
          credential.user!.uid,
        );
        if (isBanned) {
          // 정지된 계정이면 로그아웃 처리
          await signOut();
          throw Exception('정지된 계정입니다. 고객센터에 문의해주세요.');
        }
      }

      // Firebase에 사용자 정보 저장
      await _saveUserToFirestore(credential);

      // 분석 이벤트
      if (credential.user != null) {
        // 신규 사용자인지 확인 (createdAt이 최근인 경우)
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        if (!userDoc.exists || userDoc.data()?['createdAt'] == null) {
          // 재가입 방지: 이메일로 정지 확인
          final email = credential.user!.email;
          if (email != null) {
            final isEmailBanned = await AccountBanService.isEmailBanned(email);
            if (isEmailBanned) {
              await signOut();
              throw Exception('이 이메일은 정지된 계정입니다. 고객센터에 문의해주세요.');
            }
          }
          await AnalyticsService.logSignupCompleted('google');
        } else {
          await AnalyticsService.logLoginSuccess('google');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  static Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('로그인 중 오류가 발생했습니다: $e');
    }
  }

  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 이메일 정규화 및 검증
      final normalizedEmail = Sanitizer.normalizeEmail(email);
      if (normalizedEmail == null) {
        throw Exception('올바른 이메일 형식이 아닙니다.');
      }

      AppLogger.info('이메일 로그인 시도', {'email': normalizedEmail});

      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      AppLogger.info('이메일 로그인 성공', {'userId': credential.user?.uid});

      // 재가입 방지: 로그인 시 정지 상태 확인
      if (credential.user != null) {
        final isBanned = await AccountBanService.isUserBanned(
          credential.user!.uid,
        );
        if (isBanned) {
          // 정지된 계정이면 로그아웃 처리
          await signOut();
          throw Exception('정지된 계정입니다. 고객센터에 문의해주세요.');
        }
      }

      // Firebase에 사용자 정보 저장
      await _saveUserToFirestore(credential);

      // 분석 이벤트
      await AnalyticsService.logLoginSuccess('email');

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('이메일 로그인 실패 (Firebase)', e, stackTrace);
      // 에러 모니터링
      await ErrorService.recordError(
        e,
        stackTrace,
        reason: '이메일 로그인 실패',
        fatal: false,
      );
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('이메일 로그인 실패', e, stackTrace);
      // 에러 모니터링
      await ErrorService.recordError(
        e,
        stackTrace,
        reason: '이메일 로그인 실패',
        fatal: false,
      );
      throw Exception('로그인 중 오류가 발생했습니다: $e');
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 이메일 정규화 및 검증
      final normalizedEmail = Sanitizer.normalizeEmail(email);
      if (normalizedEmail == null) {
        throw Exception('올바른 이메일 형식이 아닙니다.');
      }

      // 재가입 방지: 정지된 이메일인지 확인
      final isBanned = await AccountBanService.isEmailBanned(normalizedEmail);
      if (isBanned) {
        throw Exception('이 이메일은 정지된 계정입니다. 고객센터에 문의해주세요.');
      }

      // 재가입 방지: 삭제된 계정의 이메일인지 확인
      final canRejoin = await AccountBanService.canRejoinWithEmail(
        normalizedEmail,
      );
      if (!canRejoin) {
        throw Exception('이 이메일로는 재가입할 수 없습니다.');
      }

      // 비밀번호 검증
      if (password.length < 6) {
        throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
      }

      AppLogger.info('이메일 회원가입 시도', {'email': normalizedEmail});

      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      AppLogger.info('이메일 회원가입 성공', {'userId': credential.user?.uid});

      // Firebase에 사용자 정보 저장
      await _saveUserToFirestore(credential);

      // 분석 이벤트
      await AnalyticsService.logSignupCompleted('email');

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('이메일 회원가입 실패 (Firebase)', e, stackTrace);
      // 에러 모니터링
      await ErrorService.recordError(
        e,
        stackTrace,
        reason: '이메일 회원가입 실패',
        fatal: false,
      );
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('이메일 회원가입 실패', e, stackTrace);
      // 에러 모니터링
      await ErrorService.recordError(
        e,
        stackTrace,
        reason: '이메일 회원가입 실패',
        fatal: false,
      );
      throw Exception('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  static Future<UserCredential?> linkWithCredential({
    required User user,
    required AuthCredential credential,
  }) async {
    try {
      return await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('계정 업그레이드 중 오류가 발생했습니다: $e');
    }
  }

  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다.');
      case 'email-already-in-use':
        return Exception('이미 사용 중인 이메일입니다.');
      case 'user-not-found':
        return Exception('등록되지 않은 이메일입니다.');
      case 'wrong-password':
        return Exception('비밀번호가 올바르지 않습니다.');
      case 'invalid-email':
        return Exception('올바른 이메일 형식이 아닙니다.');
      case 'user-disabled':
        return Exception('비활성화된 계정입니다.');
      case 'too-many-requests':
        return Exception('너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.');
      case 'operation-not-allowed':
        return Exception('허용되지 않은 작업입니다.');
      default:
        return Exception('인증 오류: ${e.message ?? e.code}');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
