import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prefs.dart';

class NotificationService {
  static bool _enabled = true;
  static FlutterLocalNotificationsPlugin? _notifications;

  static Future<void> init() async {
    _enabled = await PrefsService.getNotificationsEnabled();
    _notifications = FlutterLocalNotificationsPlugin();
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    
    await _notifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    
    // Android 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'komeet_channel',
      'Komeet 알림',
      description: '코밋 앱의 주요 알림 채널',
      importance: Importance.high,
    );
    await _notifications!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    await PrefsService.setNotificationsEnabled(value);
  }

  static bool get isEnabled => _enabled;

  static Future<void> showDemo(BuildContext context, {String? title, String? body}) async {
    if (!_enabled || _notifications == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_enabled ? '알림 초기화 필요' : '알림이 비활성화되어 있습니다.')),
      );
      return;
    }
    
    const androidDetails = AndroidNotificationDetails(
      'komeet_channel',
      'Komeet 알림',
      channelDescription: '코밋 앱의 주요 알림 채널',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications!.show(
      0,
      title ?? '코밋 알림',
      body ?? '알림 테스트: 설정이 정상 작동합니다.',
      details,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로컬 알림이 전송되었습니다.')),
    );
  }
  
  static Future<void> showMatchNotification(String name) async {
    if (!_enabled || _notifications == null) return;
    const androidDetails = AndroidNotificationDetails(
      'komeet_channel',
      'Komeet 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications!.show(
      1,
      '새로운 매칭!',
      '$name님과 매칭되었습니다.',
      details,
    );
  }
}


