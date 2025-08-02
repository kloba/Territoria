import 'package:hive/hive.dart';

part 'daily_stats.g.dart';

@HiveType(typeId: 1)
class DailyStats {
  @HiveField(0)
  final DateTime day;
  
  @HiveField(1)
  final double distanceKm;
  
  @HiveField(2)
  final int steps;
  
  @HiveField(3)
  final double areaKm2;

  DailyStats({
    required this.day,
    required this.distanceKm,
    required this.steps,
    required this.areaKm2,
  });

  DailyStats copyWith({
    DateTime? day,
    double? distanceKm,
    int? steps,
    double? areaKm2,
  }) {
    return DailyStats(
      day: day ?? this.day,
      distanceKm: distanceKm ?? this.distanceKm,
      steps: steps ?? this.steps,
      areaKm2: areaKm2 ?? this.areaKm2,
    );
  }
}