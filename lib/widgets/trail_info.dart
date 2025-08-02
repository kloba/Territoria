import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../models/game_state.dart';

class TrailInfo extends StatelessWidget {
  const TrailInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.currentState == GameState.insideZone) {
          return const SizedBox.shrink();
        }

        final trailLength = gameProvider.trailLengthM;
        final candidateArea = gameProvider.candidateAreaM2;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                icon: Icons.route,
                label: 'Trail',
                value: '${trailLength.toStringAsFixed(0)}m',
                color: Colors.red,
              ),
              
              if (candidateArea != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildInfoItem(
                  icon: Icons.square_foot,
                  label: 'Area',
                  value: '${candidateArea.toStringAsFixed(0)}m²',
                  color: candidateArea >= 150 ? Colors.green : Colors.orange,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}