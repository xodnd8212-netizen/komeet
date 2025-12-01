import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _kMaxDistance = 'prefs.max_distance_km';
  static const _kNotify = 'prefs.notifications_enabled';
  static const _kTokyoOnly = 'prefs.filter.tokyo_only';
  static const _kOnboardingCompleted = 'prefs.onboarding_completed';
  static const _kMinAge = 'prefs.filter.min_age';
  static const _kMaxAge = 'prefs.filter.max_age';
  static const _kGenderPreference = 'prefs.filter.gender_preference';
  static const _kDailyLikeLimit = 'prefs.daily_like_limit';
  static const _kDailyLikeCount = 'prefs.daily_like_count';
  static const _kDailyLikeResetDate = 'prefs.daily_like_reset_date';

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

  static Future<bool> getOnboardingCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingCompleted, value);
  }

  // 나이 범위 필터
  static Future<int> getMinAge() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kMinAge) ?? 18;
  }

  static Future<void> setMinAge(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMinAge, value);
  }

  static Future<int> getMaxAge() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kMaxAge) ?? 99;
  }

  static Future<void> setMaxAge(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMaxAge, value);
  }

  // 성별 선호도 필터
  static Future<String> getGenderPreference() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kGenderPreference) ?? 'any'; // 'any', 'male', 'female', 'other'
  }

  static Future<void> setGenderPreference(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kGenderPreference, value);
  }

  // 하루 좋아요 제한
  static Future<int> getDailyLikeLimit() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kDailyLikeLimit) ?? 50; // 기본 50개
  }

  static Future<void> setDailyLikeLimit(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDailyLikeLimit, value);
  }

  static Future<int> getDailyLikeCount() async {
    final p = await SharedPreferences.getInstance();
    final resetDate = p.getString(_kDailyLikeResetDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 오늘이 아니면 리셋
    if (resetDate == null || DateTime.parse(resetDate).isBefore(today)) {
      await p.setInt(_kDailyLikeCount, 0);
      await p.setString(_kDailyLikeResetDate, today.toIso8601String());
      return 0;
    }

    return p.getInt(_kDailyLikeCount) ?? 0;
  }

  static Future<void> incrementDailyLikeCount() async {
    final p = await SharedPreferences.getInstance();
    final count = await getDailyLikeCount();
    await p.setInt(_kDailyLikeCount, count + 1);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await p.setString(_kDailyLikeResetDate, today.toIso8601String());
  }

  static Future<bool> canLikeMore() async {
    final limit = await getDailyLikeLimit();
    final count = await getDailyLikeCount();
    return count < limit;
  }
}


