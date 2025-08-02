import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../models/daily_stats.dart';
import '../models/settings.dart';

class StatsProvider extends ChangeNotifier {
  DailyStats? _todayStats;
  List<DailyStats> _historicalStats = [];
  LatLng? _lastPosition;
  
  DailyStats? get todayStats => _todayStats;
  List<DailyStats> get historicalStats => _historicalStats;
  
  StatsProvider() {
    _loadStats();
    _checkForNewDay();
  }
  
  Future<void> _loadStats() async {
    final box = Hive.box('daily_stats');
    _historicalStats = box.values.cast<DailyStats>().toList();
    
    final today = _getToday();
    _todayStats = _historicalStats.firstWhere(
      (stats) => _isSameDay(stats.day, today),
      orElse: () => DailyStats(
        day: today,
        distanceKm: 0.0,
        steps: 0,
        areaKm2: 0.0,
      ),
    );
    
    notifyListeners();
  }
  
  void updatePosition(LatLng newPosition, Settings settings) {
    if (_lastPosition != null) {
      final distanceM = const Distance().as(
        LengthUnit.Meter,
        _lastPosition!,
        newPosition,
      );
      
      if (distanceM > 0) {
        _todayStats = _todayStats!.copyWith(
          distanceKm: _todayStats!.distanceKm + (distanceM / 1000),
          steps: _todayStats!.steps + (distanceM / settings.strideLengthM).round(),
        );
        
        _saveStats();
        notifyListeners();
      }
    }
    
    _lastPosition = newPosition;
  }
  
  void updateCapturedArea(double newAreaM2) {
    _todayStats = _todayStats!.copyWith(
      areaKm2: _todayStats!.areaKm2 + (newAreaM2 / 1e6),
    );
    
    _saveStats();
    notifyListeners();
  }
  
  void _checkForNewDay() {
    final now = DateTime.now();
    
    Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentDay = _getToday();
      if (!_isSameDay(_todayStats!.day, currentDay)) {
        _resetDailyStats();
      }
    });
  }
  
  void _resetDailyStats() {
    final today = _getToday();
    _todayStats = DailyStats(
      day: today,
      distanceKm: 0.0,
      steps: 0,
      areaKm2: 0.0,
    );
    
    _saveStats();
    notifyListeners();
  }
  
  Future<void> _saveStats() async {
    final box = Hive.box('daily_stats');
    
    final existingIndex = _historicalStats.indexWhere(
      (stats) => _isSameDay(stats.day, _todayStats!.day),
    );
    
    if (existingIndex >= 0) {
      _historicalStats[existingIndex] = _todayStats!;
      await box.putAt(existingIndex, _todayStats!);
    } else {
      _historicalStats.add(_todayStats!);
      await box.add(_todayStats!);
    }
  }
  
  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
           day1.month == day2.month &&
           day1.day == day2.day;
  }
}