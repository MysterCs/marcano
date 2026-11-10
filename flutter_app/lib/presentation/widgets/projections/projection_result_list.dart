import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/projection_point.dart';

/// Seccion de resultados de la proyeccion mensual.
class ProjectionResultList extends StatelessWidget {
  const ProjectionResultList({required this.projection, super.key});

  final Future<List<ProjectionPoint>>? projection;

  @override
  Widget build(BuildContext context) {
    final projection = this.projection;
    if (projection == null) return const SizedBox.shrink();
    return FutureBuilder<List<ProjectionPoint>>(
      future: projection,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('No se pudo proyectar: ${snapshot.error}');
        }
        final dateFormat = DateFormat('MMMM yyyy', 'es_ES');
        return Column(
          children: snapshot.requireData
              .map(
                (point) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(dateFormat.format(point.period)),
                    trailing:
                        Text('${point.quantity.toStringAsFixed(2)} uds.'),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
