import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// 오프라인 지원 서비스
class OfflineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isInitialized = false;

  /// 오프라인 지속성 활성화
  static Future<void> enablePersistence() async {
    if (_isInitialized) return;

    try {
      await _firestore.enablePersistence(
        const PersistenceSettings(
          synchronizeTabs: true,
        ),
      );
      _isInitialized = true;
      AppLogger.info('Firestore 오프라인 지속성 활성화');
    } catch (e) {
      // 이미 활성화되었거나 웹에서는 지원하지 않을 수 있음
      AppLogger.warning('오프라인 지속성 활성화 실패', {'error': e.toString()});
      _isInitialized = true; // 재시도 방지
    }
  }

  /// 네트워크 상태 확인
  static Future<bool> isOnline() async {
    try {
      // 간단한 방법: Firestore 연결 상태 확인
      // 실제로는 connectivity_plus 패키지 사용 권장
      return true; // 기본값은 온라인으로 가정
    } catch (e) {
      return false;
    }
  }

  /// 오프라인 큐에 작업 추가 (향후 구현)
  static Future<void> queueOfflineAction(String action, Map<String, dynamic> data) async {
    try {
      // 로컬 저장소에 작업 저장
      // 네트워크 복구 시 자동 실행
      AppLogger.info('오프라인 작업 큐에 추가', {'action': action});
    } catch (e, stackTrace) {
      AppLogger.error('오프라인 작업 큐 추가 실패', e, stackTrace);
    }
  }
}

