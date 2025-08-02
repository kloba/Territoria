import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class GpsIndicator extends StatelessWidget {
  const GpsIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final accuracy = locationProvider.accuracy ?? 0;
        final signalStrength = _getSignalStrength(accuracy);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gps_fixed,
                size: 20,
                color: _getSignalColor(signalStrength),
              ),
              const SizedBox(width: 8),
              Text(
                '${accuracy.toStringAsFixed(0)}m',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildSignalBars(signalStrength),
            ],
          ),
        );
      },
    );
  }

  int _getSignalStrength(double accuracy) {
    if (accuracy <= 5) return 4;
    if (accuracy <= 10) return 3;
    if (accuracy <= 15) return 2;
    if (accuracy <= 20) return 1;
    return 0;
  }

  Color _getSignalColor(int strength) {
    switch (strength) {
      case 4:
        return Colors.green;
      case 3:
        return Colors.lightGreen;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Widget _buildSignalBars(int strength) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < strength;
        return Container(
          width: 3,
          height: 8 + (index * 2).toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? _getSignalColor(strength) : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}