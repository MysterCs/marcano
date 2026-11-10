import 'package:flutter/material.dart';

/// Critero de proyeccion: movimiento y algoritmo.
class ProjectionCriteria extends StatelessWidget {
  const ProjectionCriteria({
    required this.movement,
    required this.strategy,
    required this.onMovementChanged,
    required this.onStrategyChanged,
    super.key,
  });

  final String movement;
  final String strategy;
  final ValueChanged<String> onMovementChanged;
  final ValueChanged<String> onStrategyChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: movement,
            decoration: const InputDecoration(labelText: 'Movimiento'),
            items: const [
              DropdownMenuItem(value: 'sale', child: Text('Ventas')),
              DropdownMenuItem(value: 'purchase', child: Text('Compras')),
            ],
            onChanged: (value) => onMovementChanged(value ?? 'sale'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: strategy,
            decoration: const InputDecoration(labelText: 'Algoritmo'),
            items: const [
              DropdownMenuItem(
                value: 'moving_average',
                child: Text('Media movil (3 meses)'),
              ),
              DropdownMenuItem(
                value: 'linear_trend',
                child: Text('Tendencia lineal'),
              ),
            ],
            onChanged: (value) =>
                onStrategyChanged(value ?? 'moving_average'),
          ),
        ],
      );
}
