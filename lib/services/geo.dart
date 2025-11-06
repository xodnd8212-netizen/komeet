import 'dart:math' as math;

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

double haversineKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;
  final dLat = _deg2rad(b.lat - a.lat);
  final dLng = _deg2rad(b.lng - a.lng);
  final sa = math.sin(dLat / 2), sb = math.sin(dLng / 2);
  final aa = sa * sa + math.cos(_deg2rad(a.lat)) * math.cos(_deg2rad(b.lat)) * sb * sb;
  final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
  return earthRadiusKm * c;
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);


