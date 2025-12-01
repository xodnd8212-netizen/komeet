import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications.dart';
import 'auth_service.dart';

class PushNotificationService {
  static FirebaseMessaging? _messaging;

  // FCM 백그라운드 메시지 핸들러 (top-level 함수)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // 백그라운드에서 메시지 수신 시 처리
    await NotificationService.showMatchNotification(
      message.data['name'] ?? '누군가',
    );
  }

  static Future<void> init() async {
    _messaging = FirebaseMessaging.instance;
    // 로컬 알림은 NotificationService를 통해 관리

    // 권한 요청
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM 토큰 가져오기
      final token = await _messaging!.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // 토큰 갱신 리스너
      _messaging!.onTokenRefresh.listen((newToken) {
        _saveFCMToken(newToken);
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 백그라운드 메시지 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // 토큰 저장 실패는 무시 (로그인 전일 수 있음)
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // 포그라운드에서 메시지 수신 시 NotificationService를 통해 알림 표시
    final notification = message.notification;
    if (notification != null) {
      NotificationService.showMatchNotification(
        notification.title ?? '알림',
      );
    }
  }

  static Future<String?> getToken() async {
    return await _messaging?.getToken();
  }

  static Future<void> saveTokenIfLoggedIn() async {
    final token = await getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging?.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging?.unsubscribeFromTopic(topic);
  }
}

