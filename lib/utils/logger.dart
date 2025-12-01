import 'package:flutter/foundation.dart';

/// 구조화된 로깅 유틸리티
class AppLogger {
  static void info(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[INFO] $timestamp: $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
    // 프로덕션에서는 Firebase Crashlytics나 Sentry로 전송
  }

  static void warning(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[WARNING] $timestamp: $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) {
      print('[ERROR] $timestamp: $message');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
      if (data != null) {
        print('  Data: $data');
      }
    }
    // 프로덕션에서는 Firebase Crashlytics로 전송
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void debug(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[DEBUG] $timestamp: $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }
}

