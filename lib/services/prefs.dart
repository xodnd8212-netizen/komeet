import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _kMaxDistance = 'prefs.max_distance_km';
  static const _kNotify = 'prefs.notifications_enabled';
  static const _kTokyoOnly = 'prefs.filter.tokyo_only';

  static Future<double> getMaxDistanceKm() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kMaxDistance) ?? 30.0;
  }

  static Future<void> setMaxDistanceKm(double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kMaxDistance, value);
  }

  static Future<bool> getNotificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotify) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotify, value);
  }

  static Future<bool> getTokyoOnly() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kTokyoOnly) ?? false;
  }

  static Future<void> setTokyoOnly(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kTokyoOnly, value);
  }
}


