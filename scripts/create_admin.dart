import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:komeet/firebase_options.dart';

// 기본 어드민 계정 정보
const String adminEmail = 'admin@komeet.app';
const String adminPassword = 'Admin123!@#';
const String adminName = '시스템 관리자';

Future<void> main() async {
  print('어드민 계정 생성 시작...');

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase 초기화 완료');

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // 기존 사용자 확인
    User? existingUser;
    try {
      final users = await auth.fetchSignInMethodsForEmail(adminEmail);
      if (users.isNotEmpty) {
        print('기존 계정이 존재합니다. 로그인 시도...');
        // 기존 계정이 있으면 로그인 시도
        try {
          final credential = await auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          existingUser = credential.user;
          print('기존 계정으로 로그인 성공');
        } catch (e) {
          print('기존 계정 로그인 실패: $e');
          print('새 계정을 생성합니다...');
        }
      }
    } catch (e) {
      print('계정 확인 중 오류: $e');
    }

    UserCredential userCredential;

    if (existingUser == null) {
      // 새 계정 생성
      print('새 어드민 계정 생성 중...');
      userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('어드민 계정 생성 완료!');
    } else {
      // 기존 계정 사용
      userCredential = await auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('기존 어드민 계정 사용');
    }

    final uid = userCredential.user!.uid;

    // Firestore에 어드민 정보 저장
    await firestore.collection('admins').doc(uid).set({
      'isAdmin': true,
      'email': adminEmail,
      'adminName': adminName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('\n✅ 어드민 계정 생성 완료!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📧 이메일: $adminEmail');
    print('🔑 비밀번호: $adminPassword');
    print('👤 이름: $adminName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('\n이 계정으로 로그인하면 자동으로 어드민 대시보드로 이동합니다.');
  } catch (e) {
    print('❌ 오류 발생: $e');
    exit(1);
  }

  exit(0);
}




