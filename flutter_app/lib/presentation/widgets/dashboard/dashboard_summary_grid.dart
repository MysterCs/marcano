import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/inventory_summary.dart';
import 'metric_card.dart';

/// Seccion de resumen del dashboard: metricas globales del inventario.
class DashboardSummaryGrid extends StatelessWidget {
  const DashboardSummaryGrid({required this.summary, super.key});

  final InventorySummary summary;

  @override
  Widget build(BuildContext context) {
    final thousands = NumberFormat.decimalPattern('es_ES');
    final currency = NumberFormat.currency(locale: 'es_ES', symbol: 'USD ');
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        MetricCard(title: 'Productos', value: thousands.format(summary.products)),
        MetricCard(title: 'Unidades', value: thousands.format(summary.units)),
        MetricCard(title: 'Stock bajo', value: thousands.format(summary.lowStock)),
        MetricCard(
          title: 'Valor inventario',
          value: currency.format(summary.inventoryValue),
        ),
      ],
    );
  }
}
