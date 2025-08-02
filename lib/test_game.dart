import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TestGame extends StatefulWidget {
  const TestGame({Key? key}) : super(key: key);

  @override
  State<TestGame> createState() => _TestGameState();
}

class _TestGameState extends State<TestGame> {
  // Test state
  LatLng? _currentPosition;
  final List<LatLng> _trail = [];
  final List<LatLng> _allPositions = [];
  List<LatLng> _territory = [];
  List<LatLng>? _capturedArea;
  Timer? _captureAnimationTimer;
  
  // Map controller
  final MapController _mapController = MapController();
  
  // Game metrics
  double _territoryArea = 0.0;
  int _captures = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize with a default position in San Francisco
    _initializeWithPosition(const LatLng(37.7749, -122.4194));
  }
  
  void _initializeWithPosition(LatLng position) {
    setState(() {
      _currentPosition = position;
      _allPositions.add(position);
      _initializeTerritory(position);
    });
  }
  
  void _initializeTerritory(LatLng center) {
    const radius = 20.0; // meters
    const points = 32;
    
    _territory.clear();
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final lat = center.latitude + (radius / 111320) * math.cos(angle);
      final lng = center.longitude + (radius / (111320 * math.cos(center.latitude * math.pi / 180))) * math.sin(angle);
      _territory.add(LatLng(lat, lng));
    }
    _territoryArea = _calculateArea(_territory);
  }
  
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentPosition = point;
      _allPositions.add(point);
      
      if (!_isInsideTerritory(point)) {
        _trail.add(point);
      } else if (_trail.isNotEmpty) {
        _captureTerritory();
      }
    });
    
    // Center map on new position
    _mapController.move(point, _mapController.camera.zoom);
  }
  
  bool _isInsideTerritory(LatLng point) {
    if (_territory.isEmpty) return false;
    
    bool inside = false;
    int j = _territory.length - 1;
    
    for (int i = 0; i < _territory.length; i++) {
      if ((_territory[i].latitude > point.latitude) != (_territory[j].latitude > point.latitude) &&
          point.longitude < (_territory[j].longitude - _territory[i].longitude) * 
          (point.latitude - _territory[i].latitude) / 
          (_territory[j].latitude - _territory[i].latitude) + _territory[i].longitude) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }
  
  void _captureTerritory() {
    if (_trail.length < 3) {
      _trail.clear();
      return;
    }
    
    List<LatLng> capturedPolygon = [];
    capturedPolygon.addAll(_trail);
    
    int exitIndex = _findClosestTerritoryIndex(_trail.first);
    int entryIndex = _findClosestTerritoryIndex(_trail.last);
    
    if (exitIndex != entryIndex) {
      int current = entryIndex;
      while (current != exitIndex) {
        capturedPolygon.add(_territory[current]);
        current = (current + 1) % _territory.length;
      }
      capturedPolygon.add(_territory[exitIndex]);
    }
    
    setState(() {
      _capturedArea = List.from(capturedPolygon);
    });
    
    _captureAnimationTimer?.cancel();
    _captureAnimationTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _territory = _expandTerritory(_territory, capturedPolygon);
        _capturedArea = null;
        _captures++;
        _territoryArea = _calculateArea(_territory);
      });
    });
    
    _trail.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Territory captured! +${_calculateArea(capturedPolygon).toStringAsFixed(0)}m²'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  int _findClosestTerritoryIndex(LatLng point) {
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < _territory.length; i++) {
      double dx = point.latitude - _territory[i].latitude;
      double dy = point.longitude - _territory[i].longitude;
      double distance = math.sqrt(dx * dx + dy * dy);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }
  
  List<LatLng> _expandTerritory(List<LatLng> territory, List<LatLng> captured) {
    List<LatLng> allPoints = [];
    allPoints.addAll(territory);
    allPoints.addAll(captured);
    
    if (allPoints.length < 3) return allPoints;
    
    int leftmost = 0;
    for (int i = 1; i < allPoints.length; i++) {
      if (allPoints[i].longitude < allPoints[leftmost].longitude) {
        leftmost = i;
      }
    }
    
    List<LatLng> hull = [];
    int p = leftmost;
    do {
      hull.add(allPoints[p]);
      int q = (p + 1) % allPoints.length;
      
      for (int i = 0; i < allPoints.length; i++) {
        if (_orientation(allPoints[p], allPoints[i], allPoints[q]) == 2) {
          q = i;
        }
      }
      
      p = q;
    } while (p != leftmost && hull.length < allPoints.length);
    
    return hull;
  }
  
  int _orientation(LatLng p, LatLng q, LatLng r) {
    double val = (q.longitude - p.longitude) * (r.latitude - p.latitude) -
                 (q.latitude - p.latitude) * (r.longitude - p.longitude);
    if (val == 0) return 0;
    return (val > 0) ? 1 : 2;
  }
  
  double _calculateArea(List<LatLng> polygon) {
    double area = 0.0;
    int n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    
    area = area.abs() / 2.0;
    return area * 111320 * 111320 * math.cos(polygon[0].latitude * math.pi / 180);
  }
  
  void _clearAll() {
    setState(() {
      _trail.clear();
      _allPositions.clear();
      _capturedArea = null;
      _captures = 0;
      if (_currentPosition != null) {
        _allPositions.add(_currentPosition!);
        _initializeTerritory(_currentPosition!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? const LatLng(37.7749, -122.4194);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mode - Click to Move'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 18,
              maxZoom: 19,
              minZoom: 15,
              backgroundColor: Colors.grey[300]!,
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.territoria',
              ),
              
              // Territory
              if (_territory.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _territory,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              
              // Captured area animation
              if (_capturedArea != null && _capturedArea!.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _capturedArea!,
                      color: Colors.green.withOpacity(0.5),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              
              // All positions
              if (_allPositions.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _allPositions,
                      color: Colors.grey.withOpacity(0.5),
                      strokeWidth: 2,
                      isDotted: true,
                    ),
                  ],
                ),
              
              // Trail
              if (_trail.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trail,
                      color: Colors.red,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              
              // Current position
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Center(
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Stats
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Mode - Click anywhere on map to move',
                    style: TextStyle(color: Colors.yellow[300], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Territory', '${_territoryArea.toStringAsFixed(0)}m²'),
                      _buildStat('Captures', _captures.toString()),
                      _buildStat('Trail', '${_trail.length} pts'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Click outside blue territory to start trail (red).\n'
                'Click back inside to capture area (green flash).',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _captureAnimationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}