class DailyStats {
  final DateTime day;
  final double distanceKm;
  final int steps;
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