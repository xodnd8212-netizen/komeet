import 'geo.dart';

class LocationService {
  static Future<bool> ensurePermission() async {
    // 권한 로직은 나중에 geolocator 설치 후 대체
    return false;
  }

  static Future<GeoPoint?> getCurrentLocation() async {
    // 현재는 플랫폼 권한/플러그인 미설치 시 null 반환
    return null;
  }
}


