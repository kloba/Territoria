import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/captured_zone.dart';
import '../models/game_state.dart';
import '../models/settings.dart';

class GameStateProvider extends ChangeNotifier {
  GameState _currentState = GameState.insideZone;
  List<CapturedZone> _capturedZones = [];
  List<LatLng> _currentTrail = [];
  List<LatLng> _currentZonePolygon = [];
  Settings _settings = Settings();
  
  static const double _initialZoneRadius = 20.0;
  static const int _minTrailVertices = 10;
  static const double _minCaptureAreaM2 = 150.0;
  static const double _simplificationTolerance = 3.0;
  
  GameState get currentState => _currentState;
  List<CapturedZone> get capturedZones => _capturedZones;
  List<LatLng> get currentTrail => _currentTrail;
  List<LatLng> get currentZonePolygon => _currentZonePolygon;
  Settings get settings => _settings;
  
  double get totalAreaKm2 {
    return _capturedZones.fold(0.0, (sum, zone) => sum + zone.areaM2) / 1e6;
  }
  
  double get trailLengthM {
    if (_currentTrail.length < 2) return 0.0;
    
    double length = 0.0;
    for (int i = 1; i < _currentTrail.length; i++) {
      length += const Distance().as(
        LengthUnit.Meter,
        _currentTrail[i - 1],
        _currentTrail[i],
      );
    }
    return length;
  }
  
  double? get candidateAreaM2 {
    if (_currentState != GameState.returnToZone || _currentTrail.length < 3) {
      return null;
    }
    
    final capturePolygon = _buildCapturePolygon();
    if (capturePolygon == null) return null;
    
    return _calculatePolygonAreaSimple(capturePolygon);
  }
  
  GameStateProvider() {
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Temporarily disabled Hive
    notifyListeners();
  }
  
  void initializeStartingZone(LatLng center) {
    if (_currentZonePolygon.isEmpty && _capturedZones.isEmpty) {
      _currentZonePolygon = _createCirclePolygon(center, _initialZoneRadius);
      _capturedZones.add(CapturedZone(
        polygon: _currentZonePolygon,
        timestamp: DateTime.now(),
        areaM2: pi * _initialZoneRadius * _initialZoneRadius,
      ));
      _saveZones();
      notifyListeners();
    } else {
      _updateCurrentZonePolygon();
    }
  }
  
  void updatePlayerPosition(LatLng position) {
    final wasInside = _isInsideZone(position);
    
    switch (_currentState) {
      case GameState.insideZone:
        if (!wasInside) {
          _currentState = GameState.outsideZoneCapturing;
          _currentTrail = [position];
          notifyListeners();
        }
        break;
        
      case GameState.outsideZoneCapturing:
        _currentTrail.add(position);
        if (wasInside && _currentTrail.length > 2) {
          _currentState = GameState.returnToZone;
        }
        notifyListeners();
        break;
        
      case GameState.returnToZone:
        if (wasInside) {
          _attemptCapture();
        } else {
          _currentState = GameState.outsideZoneCapturing;
          _currentTrail.add(position);
        }
        notifyListeners();
        break;
        
      case GameState.capture:
        _currentState = GameState.insideZone;
        notifyListeners();
        break;
    }
  }
  
  void undoTrail() {
    _currentTrail.clear();
    _currentState = GameState.insideZone;
    notifyListeners();
  }
  
  void updateSettings(Settings newSettings) {
    _settings = newSettings;
    // Temporarily disabled Hive
    notifyListeners();
  }
  
  bool _isInsideZone(LatLng point) {
    return _isPointInPolygonSimple(point, _currentZonePolygon);
  }
  
  void _attemptCapture() {
    final capturePolygon = _buildCapturePolygon();
    if (capturePolygon == null || !_validateCapture(capturePolygon)) {
      _currentState = GameState.insideZone;
      _currentTrail.clear();
      notifyListeners();
      return;
    }
    
    final simplifiedPolygon = _simplifyPolygonSimple(capturePolygon);
    final area = _calculatePolygonAreaSimple(simplifiedPolygon);
    
    final newZone = CapturedZone(
      polygon: simplifiedPolygon,
      timestamp: DateTime.now(),
      areaM2: area,
    );
    
    _capturedZones.add(newZone);
    _currentZonePolygon = _mergePolygons(_currentZonePolygon, simplifiedPolygon);
    
    _currentState = GameState.capture;
    _currentTrail.clear();
    
    _saveZones();
    notifyListeners();
  }
  
  List<LatLng>? _buildCapturePolygon() {
    if (_currentTrail.length < 3) return null;
    
    final entryPoint = _findBoundaryIntersection(_currentTrail.first, _currentTrail[1]);
    final exitPoint = _findBoundaryIntersection(
      _currentTrail[_currentTrail.length - 2],
      _currentTrail.last,
    );
    
    if (entryPoint == null || exitPoint == null) return null;
    
    final capturePolygon = <LatLng>[entryPoint];
    capturePolygon.addAll(_currentTrail.sublist(1, _currentTrail.length - 1));
    capturePolygon.add(exitPoint);
    
    final boundarySegment = _getBoundarySegment(entryPoint, exitPoint);
    capturePolygon.addAll(boundarySegment);
    
    return capturePolygon;
  }
  
  bool _validateCapture(List<LatLng> polygon) {
    final simplified = _simplifyPolygonSimple(polygon);
    if (simplified.length < _minTrailVertices) return false;
    
    final area = _calculatePolygonAreaSimple(simplified);
    if (area < _minCaptureAreaM2) return false;
    
    return !_hasSelfIntersections(simplified);
  }
  
  List<LatLng> _createCirclePolygon(LatLng center, double radiusM) {
    const numPoints = 32;
    final polygon = <LatLng>[];
    
    for (int i = 0; i < numPoints; i++) {
      final angle = (i / numPoints) * 2 * pi;
      final lat = center.latitude + (radiusM / 111320) * cos(angle);
      final lng = center.longitude + (radiusM / (111320 * cos(center.latitude * pi / 180))) * sin(angle);
      polygon.add(LatLng(lat, lng));
    }
    
    return polygon;
  }
  
  void _updateCurrentZonePolygon() {
    if (_capturedZones.isEmpty) return;
    
    _currentZonePolygon = _capturedZones.first.polygon;
    for (int i = 1; i < _capturedZones.length; i++) {
      _currentZonePolygon = _mergePolygons(_currentZonePolygon, _capturedZones[i].polygon);
    }
  }
  
  // Simplified polygon operations without turf
  List<LatLng> _mergePolygons(List<LatLng> poly1, List<LatLng> poly2) {
    // Simple merge - just return the first polygon for now
    // In a real implementation, this would compute the union
    return poly1;
  }
  
  List<LatLng> _simplifyPolygonSimple(List<LatLng> polygon) {
    // Simple Douglas-Peucker implementation would go here
    // For now, just return the original
    return polygon;
  }
  
  double _calculatePolygonAreaSimple(List<LatLng> polygon) {
    // Shoelace formula for polygon area
    double area = 0.0;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      area += (polygon[j].longitude + polygon[i].longitude) * 
              (polygon[j].latitude - polygon[i].latitude);
      j = i;
    }
    
    // Convert to square meters (approximate)
    return (area.abs() / 2.0) * 111320 * 111320 * cos(polygon[0].latitude * pi / 180);
  }
  
  bool _isPointInPolygonSimple(LatLng point, List<LatLng> polygon) {
    // Ray casting algorithm
    bool inside = false;
    double p1x = polygon.last.longitude;
    double p1y = polygon.last.latitude;
    
    for (int i = 0; i < polygon.length; i++) {
      double p2x = polygon[i].longitude;
      double p2y = polygon[i].latitude;
      
      if (((p2y > point.latitude) != (p1y > point.latitude)) &&
          (point.longitude < (p1x - p2x) * (point.latitude - p2y) / (p1y - p2y) + p2x)) {
        inside = !inside;
      }
      
      p1x = p2x;
      p1y = p2y;
    }
    
    return inside;
  }
  
  LatLng? _findBoundaryIntersection(LatLng p1, LatLng p2) {
    return p1;
  }
  
  List<LatLng> _getBoundarySegment(LatLng start, LatLng end) {
    return [];
  }
  
  bool _hasSelfIntersections(List<LatLng> polygon) {
    return false;
  }
  
  Future<void> _saveZones() async {
    // Temporarily disabled Hive
  }
  
  String exportAsGeoJson() {
    final features = _capturedZones.map((zone) => zone.toGeoJson()).toList();
    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
    };
    return geoJson.toString();
  }
}