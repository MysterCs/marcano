import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/categories/product_category_helper.dart';
import '../../../data/models/descriptive_statistics.dart';

enum CategoryChartMetric { value, units, products }

class CategoryBarChart extends StatefulWidget {
  const CategoryBarChart({
    required this.categories,
    super.key,
  });

  final List<CategoryStat> categories;

  @override
  State<CategoryBarChart> createState() => _CategoryBarChartState();
}

class _CategoryBarChartState extends State<CategoryBarChart> {
  CategoryChartMetric _metric = CategoryChartMetric.value;

  double _metricValue(CategoryStat stat) {
    switch (_metric) {
      case CategoryChartMetric.value:
        return stat.totalValue;
      case CategoryChartMetric.units:
        return stat.totalUnits.toDouble();
      case CategoryChartMetric.products:
        return stat.productCount.toDouble();
    }
  }

  String _formatMetric(CategoryStat stat) {
    final thousands = NumberFormat.decimalPattern('es_ES');
    final currency = NumberFormat.currency(locale: 'es_ES', symbol: 'USD ');
    switch (_metric) {
      case CategoryChartMetric.value:
        return currency.format(stat.totalValue);
      case CategoryChartMetric.units:
        return '${thousands.format(stat.totalUnits)} uds.';
      case CategoryChartMetric.products:
        return '${thousands.format(stat.productCount)} SKUs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.categories]
      ..sort((a, b) => _metricValue(b).compareTo(_metricValue(a)));
    final maxVal = sorted.isEmpty
        ? 1.0
        : sorted
            .map(_metricValue)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

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
                        color: const Color(0xFFE11D48).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFFE11D48),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distribución por Categoría',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Comparativa de valor, existencias y catálogo',
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
                SegmentedButton<CategoryChartMetric>(
                  segments: const [
                    ButtonSegment(
                      value: CategoryChartMetric.value,
                      label: Text('Valor USD'),
                      icon: Icon(Icons.attach_money, size: 16),
                    ),
                    ButtonSegment(
                      value: CategoryChartMetric.units,
                      label: Text('Unidades'),
                      icon: Icon(Icons.layers_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: CategoryChartMetric.products,
                      label: Text('SKUs'),
                      icon: Icon(Icons.category_outlined, size: 16),
                    ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (sel) =>
                      setState(() => _metric = sel.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Sin datos de categorías.')),
              )
            else
              ...sorted.map((stat) {
                final style = ProductCategoryHelper.styleFor(stat.category);
                final ratio = (_metricValue(stat) / maxVal).clamp(0.02, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(style.icon, size: 16, color: style.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stat.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatMetric(stat),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              width: double.infinity,
                              color: const Color(0xFF1F1F2B),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      style.color,
                                      style.color.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

