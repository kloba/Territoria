import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';

part 'captured_zone.g.dart';

@HiveType(typeId: 0)
class CapturedZone {
  @HiveField(0)
  final List<LatLng> polygon;
  
  @HiveField(1)
  final DateTime timestamp;
  
  @HiveField(2)
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

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final int typeId = 3;

  @override
  LatLng read(BinaryReader reader) {
    final lat = reader.readDouble();
    final lng = reader.readDouble();
    return LatLng(lat, lng);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
  }
}