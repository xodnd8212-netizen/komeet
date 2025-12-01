import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'admins';

  /// 현재 사용자가 어드민인지 확인
  static Future<bool> isAdmin() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      final isAdmin = doc.exists && (doc.data()?['isAdmin'] == true);
      
      if (isAdmin) {
        AppLogger.info('어드민 확인', {'userId': user.uid});
      }
      
      return isAdmin;
    } catch (e, stackTrace) {
      AppLogger.error('어드민 확인 실패', e, stackTrace);
      return false;
    }
  }

  /// 특정 사용자 ID가 어드민인지 확인
  static Future<bool> isAdminByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && (doc.data()?['isAdmin'] == true);
    } catch (e) {
      return false;
    }
  }

  /// 어드민 계정 생성 (이메일/비밀번호로)
  static Future<void> createAdminAccount({
    required String email,
    required String password,
    required String adminName,
  }) async {
    try {
      // Firebase Auth에 사용자 생성
      final userCredential = await AuthService.createUserWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential?.user == null) {
        throw Exception('사용자 생성에 실패했습니다.');
      }

      final uid = userCredential!.user!.uid;

      // Firestore에 어드민 정보 저장
      await _firestore.collection(_collection).doc(uid).set({
        'isAdmin': true,
        'email': email,
        'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('어드민 계정 생성', {'uid': uid, 'email': email});
    } catch (e, stackTrace) {
      AppLogger.error('어드민 계정 생성 실패', e, stackTrace);
      throw Exception('어드민 계정 생성 실패: $e');
    }
  }

  /// 기존 사용자를 어드민으로 승격
  static Future<void> promoteToAdmin(String uid, String adminName) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception('사용자를 찾을 수 없습니다.');
      }

      await _firestore.collection(_collection).doc(uid).set({
        'isAdmin': true,
        'email': userDoc.data()?['email'] ?? '',
        'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('사용자 어드민 승격', {'uid': uid, 'adminName': adminName});
    } catch (e, stackTrace) {
      AppLogger.error('어드민 승격 실패', e, stackTrace);
      throw Exception('어드민 승격 실패: $e');
    }
  }

  /// 어드민 정보 가져오기
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// 어드민 목록 가져오기
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isAdmin', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 모든 프로필 가져오기 (어드민 전용)
  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final snapshot = await _firestore.collection('profiles').get();
      return snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 사용자 프로필 삭제 (어드민 전용)
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('profiles').doc(userId).delete();
    } catch (e) {
      throw Exception('프로필 삭제 실패: $e');
    }
  }

  /// 모든 매칭 가져오기 (어드민 전용)
  static Future<List<Map<String, dynamic>>> getAllMatches() async {
    try {
      final snapshot = await _firestore.collection('matches').get();
      return snapshot.docs
          .map((doc) => {'matchId': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 모든 채팅방 가져오기 (어드민 전용)
  static Future<List<Map<String, dynamic>>> getAllChatRooms() async {
    try {
      final snapshot = await _firestore.collection('chatRooms').get();
      return snapshot.docs
          .map((doc) => {'roomId': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }
}
