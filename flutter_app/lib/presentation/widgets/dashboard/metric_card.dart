import 'package:flutter/material.dart';

/// Tarjeta metrica del dashboard (productos, unidades, stock bajo, valor).
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    super.key,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      );
}
