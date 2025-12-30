import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

/// 계정 정지 및 재가입 방지 서비스
class AccountBanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _bannedAccountsCollection = 'banned_accounts';
  static const String _deletedAccountsCollection = 'deleted_accounts';

  /// 계정 정지
  /// [userId]: 정지할 사용자 UID
  /// [reason]: 정지 사유
  /// [durationDays]: 정지 기간 (일), null이면 영구 정지
  static Future<bool> banAccount({
    required String userId,
    required String reason,
    int? durationDays,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('사용자를 찾을 수 없습니다.');
      }

      final userData = userDoc.data()!;
      final email = userData['email'] as String?;
      if (email == null) {
        throw Exception('이메일 정보가 없습니다.');
      }

      final banData = {
        'userId': userId,
        'email': email,
        'reason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
        'isPermanent': durationDays == null,
        'expiresAt': durationDays != null
            ? DateTime.now().add(Duration(days: durationDays)).toIso8601String()
            : null,
        'status': 'active', // active, expired, revoked
      };

      await _firestore
          .collection(_bannedAccountsCollection)
          .doc(userId)
          .set(banData);

      // 사용자 문서에 정지 상태 표시
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        'banReason': reason,
      });

      AppLogger.info('계정 정지', {
        'userId': userId,
        'email': email,
        'reason': reason,
        'durationDays': durationDays,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('계정 정지 실패', e, stackTrace);
      return false;
    }
  }

  /// 계정 정지 해제
  static Future<bool> unbanAccount(String userId) async {
    try {
      final banDoc = await _firestore
          .collection(_bannedAccountsCollection)
          .doc(userId)
          .get();

      if (!banDoc.exists) {
        return false;
      }

      // 정지 상태를 revoked로 변경
      await banDoc.reference.update({
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
      });

      // 사용자 문서에서 정지 상태 제거
      await _firestore.collection('users').doc(userId).update({
        'isBanned': FieldValue.delete(),
        'bannedAt': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });

      AppLogger.info('계정 정지 해제', {'userId': userId});
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('계정 정지 해제 실패', e, stackTrace);
      return false;
    }
  }

  /// 이메일로 정지된 계정인지 확인
  static Future<bool> isEmailBanned(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 정지된 계정 컬렉션에서 이메일로 검색
      final snapshot = await _firestore
          .collection(_bannedAccountsCollection)
          .where('email', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final banData = snapshot.docs.first.data();

      // 영구 정지인지 확인
      if (banData['isPermanent'] == true) {
        return true;
      }

      // 기간 정지인 경우 만료일 확인
      final expiresAt = banData['expiresAt'] as String?;
      if (expiresAt != null) {
        final expiresDate = DateTime.parse(expiresAt);
        if (DateTime.now().isBefore(expiresDate)) {
          return true; // 아직 정지 기간 중
        } else {
          // 만료된 정지는 자동으로 비활성화
          await snapshot.docs.first.reference.update({'status': 'expired'});
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('이메일 정지 확인 실패', e);
      // 에러 발생 시 안전하게 false 반환 (정상 사용자에게 영향 없도록)
      return false;
    }
  }

  /// 사용자 UID로 정지된 계정인지 확인
  static Future<bool> isUserBanned(String userId) async {
    try {
      final banDoc = await _firestore
          .collection(_bannedAccountsCollection)
          .doc(userId)
          .get();

      if (!banDoc.exists) {
        return false;
      }

      final banData = banDoc.data()!;
      if (banData['status'] != 'active') {
        return false;
      }

      // 영구 정지인지 확인
      if (banData['isPermanent'] == true) {
        return true;
      }

      // 기간 정지인 경우 만료일 확인
      final expiresAt = banData['expiresAt'] as String?;
      if (expiresAt != null) {
        final expiresDate = DateTime.parse(expiresAt);
        if (DateTime.now().isBefore(expiresDate)) {
          return true; // 아직 정지 기간 중
        } else {
          // 만료된 정지는 자동으로 비활성화
          await banDoc.reference.update({'status': 'expired'});
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('사용자 정지 확인 실패', e);
      return false;
    }
  }

  /// 계정 삭제 기록 (재가입 방지용)
  static Future<bool> recordAccountDeletion({
    required String userId,
    required String email,
    String? reason,
  }) async {
    try {
      await _firestore.collection(_deletedAccountsCollection).doc(userId).set({
        'userId': userId,
        'email': email.trim().toLowerCase(),
        'deletedAt': FieldValue.serverTimestamp(),
        'reason': reason ?? 'user_request',
        'canRejoin': false, // 재가입 불가
      });

      AppLogger.info('계정 삭제 기록', {'userId': userId, 'email': email});
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('계정 삭제 기록 실패', e, stackTrace);
      return false;
    }
  }

  /// 삭제된 계정의 이메일로 재가입 가능한지 확인
  static Future<bool> canRejoinWithEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 삭제된 계정 컬렉션에서 이메일로 검색
      final snapshot = await _firestore
          .collection(_deletedAccountsCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return true; // 삭제 기록이 없으면 재가입 가능
      }

      final deletedData = snapshot.docs.first.data();
      return deletedData['canRejoin'] == true;
    } catch (e) {
      AppLogger.error('재가입 가능 여부 확인 실패', e);
      // 에러 발생 시 안전하게 true 반환 (정상 사용자에게 영향 없도록)
      return true;
    }
  }

  /// 정지된 계정 목록 가져오기 (관리자용)
  static Future<List<Map<String, dynamic>>> getBannedAccounts() async {
    try {
      final snapshot = await _firestore
          .collection(_bannedAccountsCollection)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }
}
