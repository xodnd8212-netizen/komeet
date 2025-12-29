import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';
import '../utils/sanitizer.dart';

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

      // Firebase에 사용자 정보 저장
      if (credential != null) {
        await _saveUserToFirestore(credential);
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

      // Firebase에 사용자 정보 저장
      await _saveUserToFirestore(credential);

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('이메일 로그인 실패 (Firebase)', e, stackTrace);
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('이메일 로그인 실패', e, stackTrace);
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

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('이메일 회원가입 실패 (Firebase)', e, stackTrace);
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('이메일 회원가입 실패', e, stackTrace);
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
