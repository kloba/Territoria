import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SimpleGame extends StatefulWidget {
  const SimpleGame({Key? key}) : super(key: key);

  @override
  State<SimpleGame> createState() => _SimpleGameState();
}

class _SimpleGameState extends State<SimpleGame> {
  // Game state
  bool _hasPermission = false;
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';
  
  // Location data
  Position? _currentPosition;
  final List<LatLng> _trail = [];
  final List<LatLng> _territory = [];
  List<LatLng>? _capturedArea; // Temporary captured area to show
  Timer? _captureAnimationTimer;
  
  // Map controller
  final MapController _mapController = MapController();
  
  // Game metrics
  double _distanceWalked = 0.0;
  double _territoryArea = 0.0;
  int _captures = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    setState(() {
      _statusMessage = 'Checking location services...';
    });
    
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Location services are disabled';
        });
        return;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Requesting location permission...';
        });
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Location permission permanently denied';
        });
        return;
      }
      
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Location permission denied';
        });
        return;
      }
      
      // Permission granted
      setState(() {
        _hasPermission = true;
        _statusMessage = 'Starting location tracking...';
      });
      
      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition();
      
      // Initialize territory around starting position
      _initializeTerritory();
      
      // Start tracking
      _startLocationTracking();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  void _initializeTerritory() {
    if (_currentPosition == null) return;
    
    // Create initial circular territory (20m radius)
    final center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    const radius = 20.0; // meters
    const points = 32;
    
    _territory.clear();
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final lat = center.latitude + (radius / 111320) * math.cos(angle);
      final lng = center.longitude + (radius / (111320 * math.cos(center.latitude * math.pi / 180))) * math.sin(angle);
      _territory.add(LatLng(lat, lng));
    }
  }
  
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters
    );
    
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        // Filter out poor accuracy readings
        if (position.accuracy > 20.0) {
          return; // Skip this update
        }
        
        setState(() {
          // Update distance
          if (_currentPosition != null) {
            _distanceWalked += Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              position.latitude,
              position.longitude,
            );
          }
          
          _currentPosition = position;
          
          // Add to trail if outside territory
          final currentLatLng = LatLng(position.latitude, position.longitude);
          if (!_isInsideTerritory(currentLatLng)) {
            _trail.add(currentLatLng);
          } else if (_trail.isNotEmpty) {
            // Returned to territory - capture!
            _captureTerritory();
          }
          
          // Center map on current position
          try {
            _mapController.move(currentLatLng, _mapController.camera.zoom);
          } catch (e) {
            // Map controller might not be ready yet
          }
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Location error: $error';
        });
      },
    );
  }
  
  bool _isInsideTerritory(LatLng point) {
    // Simple point-in-polygon test
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
    
    // Create captured area polygon (trail + territory segment)
    List<LatLng> capturedPolygon = [];
    
    // Add all trail points
    capturedPolygon.addAll(_trail);
    
    // Find where trail exits and enters territory
    int exitIndex = _findClosestTerritoryIndex(_trail.first);
    int entryIndex = _findClosestTerritoryIndex(_trail.last);
    
    // Add territory points to close the loop
    if (exitIndex != entryIndex) {
      // Go clockwise from entry to exit
      int current = entryIndex;
      while (current != exitIndex) {
        capturedPolygon.add(_territory[current]);
        current = (current + 1) % _territory.length;
      }
      capturedPolygon.add(_territory[exitIndex]);
    }
    
    // Show captured area temporarily
    setState(() {
      _capturedArea = List.from(capturedPolygon);
    });
    
    // Animate for 1 second then merge
    _captureAnimationTimer?.cancel();
    _captureAnimationTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        // Merge captured area into territory
        _territory = _expandTerritory(_territory, capturedPolygon);
        _capturedArea = null;
        
        // Update metrics
        _captures++;
        _territoryArea = _calculateArea(_territory);
      });
    });
    
    // Clear trail immediately
    _trail.clear();
    
    // Show capture notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Territory captured! +${_calculateArea(capturedPolygon).toStringAsFixed(0)}m²'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  List<LatLng> _expandTerritory(List<LatLng> territory, List<LatLng> captured) {
    // Find convex hull of all points for simple union
    List<LatLng> allPoints = [];
    allPoints.addAll(territory);
    allPoints.addAll(captured);
    
    // Simple convex hull using gift wrapping algorithm
    if (allPoints.length < 3) return allPoints;
    
    // Find leftmost point
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
    
    return _simplifyPolygon(hull);
  }
  
  int _orientation(LatLng p, LatLng q, LatLng r) {
    double val = (q.longitude - p.longitude) * (r.latitude - p.latitude) -
                 (q.latitude - p.latitude) * (r.longitude - p.longitude);
    if (val == 0) return 0;
    return (val > 0) ? 1 : 2;
  }
  
  int _findClosestTerritoryIndex(LatLng point) {
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < _territory.length; i++) {
      double distance = Geolocator.distanceBetween(
        point.latitude, point.longitude,
        _territory[i].latitude, _territory[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }
  
  List<LatLng> _simplifyPolygon(List<LatLng> points) {
    // Simple Douglas-Peucker simplification
    if (points.length < 3) return points;
    
    const double tolerance = 5.0; // meters
    List<LatLng> simplified = [];
    
    // Always keep first and last
    simplified.add(points.first);
    
    for (int i = 1; i < points.length - 1; i++) {
      // Keep point if it's far enough from the line between neighbors
      double distance = _pointToLineDistance(
        points[i],
        points[i - 1],
        points[i + 1],
      );
      if (distance > tolerance) {
        simplified.add(points[i]);
      }
    }
    
    simplified.add(points.last);
    return simplified;
  }
  
  double _pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    double A = point.latitude - lineStart.latitude;
    double B = point.longitude - lineStart.longitude;
    double C = lineEnd.latitude - lineStart.latitude;
    double D = lineEnd.longitude - lineStart.longitude;
    
    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = dot / lenSq;
    
    double xx, yy;
    
    if (param < 0) {
      xx = lineStart.latitude;
      yy = lineStart.longitude;
    } else if (param > 1) {
      xx = lineEnd.latitude;
      yy = lineEnd.longitude;
    } else {
      xx = lineStart.latitude + param * C;
      yy = lineStart.longitude + param * D;
    }
    
    return Geolocator.distanceBetween(
      point.latitude, point.longitude,
      xx, yy,
    );
  }
  
  double _calculateArea(List<LatLng> polygon) {
    // Shoelace formula for polygon area
    double area = 0.0;
    int n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Convert to square meters (approximate)
    return area * 111320 * 111320 * math.cos(polygon[0].latitude * math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_hasPermission) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _initializeGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final currentLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(0, 0);
    
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: 18,
              maxZoom: 19,
              minZoom: 15,
              backgroundColor: Colors.grey[300]!,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.territoria',
                maxZoom: 19,
                retinaMode: false,
                errorTileCallback: (tile, error, stackTrace) {
                  print('Error loading tile: $error');
                },
              ),
              
              // Territory polygon
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
              
              // Captured area animation (shows temporarily)
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
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: currentLatLng,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
          
          // Stats overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Distance', '${(_distanceWalked / 1000).toStringAsFixed(2)} km'),
                    _buildStat('Territory', '${_territoryArea.toStringAsFixed(0)} m²'),
                    _buildStat('Captures', _captures.toString()),
                    if (_currentPosition != null)
                      _buildStat('GPS', '±${_currentPosition!.accuracy.toStringAsFixed(0)}m'),
                  ],
                ),
              ),
            ),
          ),
          
          // Trail indicator
          if (_trail.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recording trail: ${_trail.length} points',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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