import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/location_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/game_map.dart';
import '../widgets/stats_overlay.dart';
import '../widgets/gps_indicator.dart';
import '../widgets/trail_info.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MapController _mapController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationProvider>();
      final gameProvider = context.read<GameStateProvider>();
      
      if (locationProvider.currentLatLng != null) {
        gameProvider.initializeStartingZone(locationProvider.currentLatLng!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GameMap(),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GpsIndicator(),
                    
                    Consumer<GameStateProvider>(
                      builder: (context, gameProvider, child) {
                        return IconButton(
                          icon: Icon(
                            Icons.undo,
                            color: gameProvider.currentTrail.isNotEmpty
                                ? Colors.black
                                : Colors.grey,
                          ),
                          onPressed: gameProvider.currentTrail.isNotEmpty
                              ? gameProvider.undoTrail
                              : null,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TrailInfo(),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showStats ? Icons.close : Icons.bar_chart,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _showStats = !_showStats;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_showStats)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: SafeArea(
                child: StatsOverlay(
                  onClose: () {
                    setState(() {
                      _showStats = false;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}