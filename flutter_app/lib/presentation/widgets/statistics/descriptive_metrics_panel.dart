import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/descriptive_statistics.dart';

enum DescriptiveVariable { stock, unitCost, totalValue }

class DescriptiveMetricsPanel extends StatefulWidget {
  const DescriptiveMetricsPanel({
    required this.statistics,
    super.key,
  });

  final DescriptiveStatistics statistics;

  @override
  State<DescriptiveMetricsPanel> createState() =>
      _DescriptiveMetricsPanelState();
}

class _DescriptiveMetricsPanelState extends State<DescriptiveMetricsPanel> {
  DescriptiveVariable _variable = DescriptiveVariable.stock;

  MetricDistribution get _current {
    switch (_variable) {
      case DescriptiveVariable.stock:
        return widget.statistics.stockDistribution;
      case DescriptiveVariable.unitCost:
        return widget.statistics.costDistribution;
      case DescriptiveVariable.totalValue:
        return widget.statistics.valueDistribution;
    }
  }

  String _format(double value) {
    final dec = NumberFormat('#,##0.00', 'es_ES');
    if (_variable == DescriptiveVariable.stock) {
      return '${dec.format(value)} uds.';
    }
    return 'USD ${dec.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _current;
    final dec = NumberFormat('#,##0.00', 'es_ES');

    final items = [
      _StatTileData(
        label: 'Media (Promedio)',
        value: _format(dist.mean),
        subtitle: 'Tendencia central aritmética',
        icon: Icons.functions_rounded,
        color: const Color(0xFFE11D48),
      ),
      _StatTileData(
        label: 'Mediana (P50 / Q2)',
        value: _format(dist.median),
        subtitle: 'Valor central del inventario',
        icon: Icons.vertical_align_center_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _StatTileData(
        label: 'Moda',
        value: _format(dist.mode),
        subtitle: 'Valor más frecuente',
        icon: Icons.repeat_rounded,
        color: const Color(0xFFF97316),
      ),
      _StatTileData(
        label: 'Desviación Estándar (σ)',
        value: _format(dist.stdDev),
        subtitle: 'CV: ${dec.format(dist.cv)}% de dispersión',
        icon: Icons.auto_graph_outlined,
        color: const Color(0xFF10B981),
      ),
      _StatTileData(
        label: 'Cuartiles (Q1 - Q3)',
        value: '${dec.format(dist.p25)} — ${dec.format(dist.p75)}',
        subtitle: 'Rango Intercuartílico (IQR): ${dec.format(dist.iqr)}',
        icon: Icons.view_week_outlined,
        color: const Color(0xFF8B5CF6),
      ),
      _StatTileData(
        label: 'Mínimo / Máximo / P90',
        value: '${dec.format(dist.minimum)} — ${dec.format(dist.maximum)}',
        subtitle: 'Percentil 90 (P90): ${_format(dist.p90)}',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medidas de Tendencia Central y Dispersión',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Análisis descriptivo sobre existencias, costos y valorización',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white60,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SegmentedButton<DescriptiveVariable>(
                  segments: const [
                    ButtonSegment(
                      value: DescriptiveVariable.stock,
                      label: Text('Existencias'),
                      icon: Icon(Icons.inventory_2_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: DescriptiveVariable.unitCost,
                      label: Text('Costo Unitario'),
                      icon: Icon(Icons.price_change_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: DescriptiveVariable.totalValue,
                      label: Text('Valor Total'),
                      icon: Icon(Icons.savings_outlined, size: 16),
                    ),
                  ],
                  selected: {_variable},
                  onSelectionChanged: (sel) =>
                      setState(() => _variable = sel.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 560 ? 2 : 1);
                final itemWidth =
                    (constraints.maxWidth - (12 * (columns - 1))) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: items
                      .map(
                        (item) => SizedBox(
                          width: itemWidth,
                          child: _StatDetailCard(data: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTileData {
  const _StatTileData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _StatDetailCard extends StatelessWidget {
  const _StatDetailCard({required this.data});

  final _StatTileData data;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2B).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: data.color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
