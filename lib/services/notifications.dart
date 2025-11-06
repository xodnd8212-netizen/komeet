import 'package:flutter/material.dart';
import 'prefs.dart';

class NotificationService {
  static bool _enabled = true;

  static Future<void> init() async {
    _enabled = await PrefsService.getNotificationsEnabled();
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    await PrefsService.setNotificationsEnabled(value);
  }

  static bool get isEnabled => _enabled;

  static Future<void> showDemo(BuildContext context, {String? title, String? body}) async {
    if (!_enabled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body ?? '알림 테스트: 설정이 정상 작동합니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


