import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/location_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/map_painter.dart';

class GameMap extends StatefulWidget {
  const GameMap({Key? key}) : super(key: key);

  @override
  State<GameMap> createState() => _GameMapState();
}

class _GameMapState extends State<GameMap> {
  late final MapController _mapController;
  bool _hasInitializedMap = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocationProvider, GameStateProvider, StatsProvider>(
      builder: (context, locationProvider, gameProvider, statsProvider, child) {
        final currentPosition = locationProvider.currentLatLng;
        
        if (currentPosition != null) {
          gameProvider.updatePlayerPosition(currentPosition);
          statsProvider.updatePosition(currentPosition, gameProvider.settings);
          
          if (!_hasInitializedMap) {
            _hasInitializedMap = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(currentPosition, 18);
              gameProvider.initializeStartingZone(currentPosition);
            });
          } else {
            _mapController.move(currentPosition, _mapController.camera.zoom);
          }
        }
        
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition ?? const LatLng(0, 0),
                initialZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.territoria',
                ),
                
                if (currentPosition != null)
                  CustomPaint(
                    size: Size.infinite,
                    painter: MapPainter(
                      mapController: _mapController,
                      playerPosition: currentPosition,
                      ownedZone: gameProvider.currentZonePolygon,
                      currentTrail: gameProvider.currentTrail,
                      gameState: gameProvider.currentState,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}