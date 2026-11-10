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
        MetricCard(
          title: 'Productos',
          value: thousands.format(summary.products),
          icon: Icons.inventory_2_outlined,
          accentColor: const Color(0xFF3B82F6),
        ),
        MetricCard(
          title: 'Unidades',
          value: thousands.format(summary.units),
          icon: Icons.layers_outlined,
          accentColor: const Color(0xFF10B981),
        ),
        MetricCard(
          title: 'Stock bajo',
          value: thousands.format(summary.lowStock),
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xFFF97316),
        ),
        MetricCard(
          title: 'Valor inventario',
          value: currency.format(summary.inventoryValue),
          icon: Icons.payments_outlined,
          accentColor: const Color(0xFFE11D48),
        ),
      ],
    );
  }
}
