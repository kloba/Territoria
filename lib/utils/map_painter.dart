import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/game_state.dart';

class MapPainter extends CustomPainter {
  final MapController mapController;
  final LatLng playerPosition;
  final List<LatLng> ownedZone;
  final List<LatLng> currentTrail;
  final GameState gameState;

  MapPainter({
    required this.mapController,
    required this.playerPosition,
    required this.ownedZone,
    required this.currentTrail,
    required this.gameState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ownedZone.isNotEmpty) {
      _drawZone(canvas, ownedZone);
    }
    
    if (currentTrail.isNotEmpty && gameState != GameState.insideZone) {
      _drawTrail(canvas, currentTrail);
    }
    
    _drawPlayer(canvas, playerPosition);
  }

  void _drawZone(Canvas canvas, List<LatLng> zone) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = ui.Path();
    for (int i = 0; i < zone.length; i++) {
      final point = _latLngToScreen(zone[i]);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawTrail(Canvas canvas, List<LatLng> trail) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    if (trail.length < 2) return;

    for (int i = 1; i < trail.length; i++) {
      final start = _latLngToScreen(trail[i - 1]);
      final end = _latLngToScreen(trail[i]);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawPlayer(Canvas canvas, LatLng position) {
    final center = _latLngToScreen(position);
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      Offset(center.dx, center.dy + 2),
      12,
      shadowPaint,
    );
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 10, paint);
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, 10, borderPaint);
    
    final innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, innerPaint);
  }

  Offset _latLngToScreen(LatLng latLng) {
    final point = mapController.camera.latLngToScreenPoint(latLng);
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return playerPosition != oldDelegate.playerPosition ||
        ownedZone.length != oldDelegate.ownedZone.length ||
        currentTrail.length != oldDelegate.currentTrail.length ||
        gameState != oldDelegate.gameState;
  }
}