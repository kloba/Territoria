import 'package:latlong2/latlong.dart';

class CapturedZone {
  final List<LatLng> polygon;
  final DateTime timestamp;
  final double areaM2;

  CapturedZone({
    required this.polygon,
    required this.timestamp,
    required this.areaM2,
  });

  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Feature',
      'properties': {
        'timestamp': timestamp.toIso8601String(),
        'areaM2': areaM2,
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          polygon.map((p) => [p.longitude, p.latitude]).toList(),
        ],
      },
    };
  }
}