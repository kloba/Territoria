import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  bool _hasPermission = false;
  Position? _currentPosition;
  LatLng? _lastKeptPoint;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _recentPositions = [];
  
  static const double _accuracyThreshold = 20.0;
  static const double _distanceThreshold = 3.0;
  static const int _smoothingWindow = 5;
  
  bool get hasPermission => _hasPermission;
  Position? get currentPosition => _currentPosition;
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  double? get accuracy => _currentPosition?.accuracy;
  
  LocationProvider() {
    _checkPermission();
  }
  
  Future<void> _checkPermission() async {
    final permission = await Permission.location.status;
    _hasPermission = permission.isGranted;
    if (_hasPermission) {
      _startLocationTracking();
    }
    notifyListeners();
  }
  
  Future<void> requestPermission() async {
    final permission = await Permission.location.request();
    _hasPermission = permission.isGranted;
    if (_hasPermission) {
      _startLocationTracking();
    }
    notifyListeners();
  }
  
  void _startLocationTracking() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_handlePositionUpdate);
  }
  
  void _handlePositionUpdate(Position position) {
    if (position.accuracy > _accuracyThreshold) {
      return;
    }
    
    final newPoint = LatLng(position.latitude, position.longitude);
    
    if (_lastKeptPoint != null) {
      final distance = const Distance().as(LengthUnit.Meter, _lastKeptPoint!, newPoint);
      if (distance < _distanceThreshold) {
        return;
      }
    }
    
    _recentPositions.add(newPoint);
    if (_recentPositions.length > _smoothingWindow) {
      _recentPositions.removeAt(0);
    }
    
    if (_recentPositions.length >= _smoothingWindow) {
      position = _applySmoothing(position);
    }
    
    _currentPosition = position;
    _lastKeptPoint = newPoint;
    notifyListeners();
  }
  
  Position _applySmoothing(Position currentPosition) {
    double avgLat = 0;
    double avgLng = 0;
    
    for (final pos in _recentPositions) {
      avgLat += pos.latitude;
      avgLng += pos.longitude;
    }
    
    avgLat /= _recentPositions.length;
    avgLng /= _recentPositions.length;
    
    return Position(
      latitude: avgLat,
      longitude: avgLng,
      timestamp: currentPosition.timestamp,
      accuracy: currentPosition.accuracy,
      altitude: currentPosition.altitude,
      altitudeAccuracy: currentPosition.altitudeAccuracy,
      heading: currentPosition.heading,
      headingAccuracy: currentPosition.headingAccuracy,
      speed: currentPosition.speed,
      speedAccuracy: currentPosition.speedAccuracy,
    );
  }
  
  void setUpdateRate(Duration rate) {
    _positionStream?.cancel();
    
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: rate.inSeconds == 1 ? 1 : 5,
    );
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_handlePositionUpdate);
  }
  
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}