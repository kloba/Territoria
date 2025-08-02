class Settings {
  final double strideLengthM;
  final String captureMode;

  Settings({
    this.strideLengthM = 0.75,
    this.captureMode = 'return_to_zone',
  });

  Settings copyWith({
    double? strideLengthM,
    String? captureMode,
  }) {
    return Settings(
      strideLengthM: strideLengthM ?? this.strideLengthM,
      captureMode: captureMode ?? this.captureMode,
    );
  }
}