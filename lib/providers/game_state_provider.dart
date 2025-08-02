import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf_dart/turf.dart' as turf;
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
    
    return _calculatePolygonArea(capturePolygon);
  }
  
  GameStateProvider() {
    _loadData();
  }
  
  Future<void> _loadData() async {
    final zonesBox = Hive.box('captured_zones');
    final settingsBox = Hive.box('settings');
    
    _capturedZones = zonesBox.values.cast<CapturedZone>().toList();
    
    if (settingsBox.containsKey('settings')) {
      _settings = settingsBox.get('settings') as Settings;
    }
    
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
    final settingsBox = Hive.box('settings');
    settingsBox.put('settings', _settings);
    notifyListeners();
  }
  
  bool _isInsideZone(LatLng point) {
    return _isPointInPolygon(point, _currentZonePolygon);
  }
  
  void _attemptCapture() {
    final capturePolygon = _buildCapturePolygon();
    if (capturePolygon == null || !_validateCapture(capturePolygon)) {
      _currentState = GameState.insideZone;
      _currentTrail.clear();
      notifyListeners();
      return;
    }
    
    final simplifiedPolygon = _simplifyPolygon(capturePolygon);
    final area = _calculatePolygonArea(simplifiedPolygon);
    
    final newZone = CapturedZone(
      polygon: simplifiedPolygon,
      timestamp: DateTime.now(),
      areaM2: area,
    );
    
    _capturedZones.add(newZone);
    _currentZonePolygon = _unionPolygons(_currentZonePolygon, simplifiedPolygon);
    
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
    final simplified = _simplifyPolygon(polygon);
    if (simplified.length < _minTrailVertices) return false;
    
    final area = _calculatePolygonArea(simplified);
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
      _currentZonePolygon = _unionPolygons(_currentZonePolygon, _capturedZones[i].polygon);
    }
  }
  
  List<LatLng> _unionPolygons(List<LatLng> poly1, List<LatLng> poly2) {
    final coords1 = poly1.map((p) => turf.Position(p.longitude, p.latitude)).toList();
    final coords2 = poly2.map((p) => turf.Position(p.longitude, p.latitude)).toList();
    
    final polygon1 = turf.Polygon(coordinates: [coords1]);
    final polygon2 = turf.Polygon(coordinates: [coords2]);
    
    final union = turf.union(polygon1, polygon2);
    if (union == null) return poly1;
    
    final unionCoords = union.coordinates.first;
    return unionCoords.map((pos) => LatLng(pos.lat, pos.lng)).toList();
  }
  
  List<LatLng> _simplifyPolygon(List<LatLng> polygon) {
    final coords = polygon.map((p) => turf.Position(p.longitude, p.latitude)).toList();
    final lineString = turf.LineString(coordinates: coords);
    final simplified = turf.simplify(lineString, tolerance: _simplificationTolerance / 111320);
    
    return simplified.coordinates.map((pos) => LatLng(pos.lat, pos.lng)).toList();
  }
  
  double _calculatePolygonArea(List<LatLng> polygon) {
    final coords = polygon.map((p) => turf.Position(p.longitude, p.latitude)).toList();
    final turfPolygon = turf.Polygon(coordinates: [coords]);
    return turf.area(turfPolygon).toDouble();
  }
  
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    final turfPoint = turf.Point(coordinates: turf.Position(point.longitude, point.latitude));
    final coords = polygon.map((p) => turf.Position(p.longitude, p.latitude)).toList();
    final turfPolygon = turf.Polygon(coordinates: [coords]);
    
    return turf.booleanPointInPolygon(turfPoint, turfPolygon);
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
    final box = Hive.box('captured_zones');
    await box.clear();
    for (int i = 0; i < _capturedZones.length; i++) {
      await box.put(i, _capturedZones[i]);
    }
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