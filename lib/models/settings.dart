import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings {
  @HiveField(0)
  final double strideLengthM;
  
  @HiveField(1)
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