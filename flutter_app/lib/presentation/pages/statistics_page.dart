import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/categories/product_category_helper.dart';
import '../../core/export/file_exporter.dart';
import '../../data/models/descriptive_statistics.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../widgets/dashboard/metric_card.dart';
import '../widgets/statistics/category_bar_chart.dart';
import '../widgets/statistics/descriptive_metrics_panel.dart';
import '../widgets/statistics/monthly_rotation_chart.dart';
import '../widgets/statistics/stock_health_donut_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    required this.repository,
    super.key,
  });

  final InventoryRepository repository;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<DescriptiveStatistics> _statsFuture;
  String _selectedCategory = 'Todas';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _load();
  }

  Future<DescriptiveStatistics> _load() =>
      widget.repository.getDescriptiveStatistics(
        category: _selectedCategory == 'Todas' ? null : _selectedCategory,
      );

  void _refresh() => setState(() => _statsFuture = _load());

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _statsFuture = _load();
    });
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final bytes = await widget.repository.exportStatistics(
        format: format,
        category: _selectedCategory == 'Todas' ? null : _selectedCategory,
      );
      final isExcel = format == 'xlsx';
      final filename = isExcel
          ? 'estadisticas_inventario_marcano.xlsx'
          : 'estadisticas_inventario_marcano.csv';
      final mime = isExcel
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv;charset=utf-8';
      final savedLocation = await FileExporter.saveBytes(
        bytes: bytes,
        filename: filename,
        mimeType: mime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte exportado exitosamente: $savedLocation'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thousands = NumberFormat.decimalPattern('es_ES');
    final currency = NumberFormat.currency(locale: 'es_ES', symbol: 'USD ');
    final categories = ['Todas', ...ProductCategoryHelper.allCategories];

    return FutureBuilder<DescriptiveStatistics>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se pudieron cargar las estadísticas descriptivas.',
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.requireData;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1F1224),
                    Color(0xFF141829),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                ),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Estadísticas Descriptivas',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dashboard analítico, distribución por categorías y exportación de datos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exporting ? null : () => _export('csv'),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('Exportar CSV'),
                      ),
                      FilledButton.icon(
                        onPressed: _exporting ? null : () => _export('xlsx'),
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Exportar Excel (.xlsx)'),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar estadísticas',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: categories[i] == 'Todas'
                          ? const Icon(Icons.apps_rounded, size: 16)
                          : Icon(
                              ProductCategoryHelper.styleFor(categories[i])
                                  .icon,
                              size: 16,
                              color:
                                  ProductCategoryHelper.styleFor(categories[i])
                                      .color,
                            ),
                      label: Text(categories[i]),
                      selected: _selectedCategory == categories[i],
                      onSelected: (_) => _selectCategory(categories[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MetricCard(
                  title: 'Productos analizados',
                  value: thousands.format(stats.totalProducts),
                  icon: Icons.inventory_2_outlined,
                  accentColor: const Color(0xFF3B82F6),
                ),
                MetricCard(
                  title: 'Unidades totales',
                  value: thousands.format(stats.totalUnits),
                  icon: Icons.layers_outlined,
                  accentColor: const Color(0xFF10B981),
                ),
                MetricCard(
                  title: 'Categorías activas',
                  value: '${stats.activeCategories}',
                  icon: Icons.category_outlined,
                  accentColor: const Color(0xFFF97316),
                ),
                MetricCard(
                  title: 'Valor total',
                  value: currency.format(stats.totalInventoryValue),
                  icon: Icons.account_balance_wallet_outlined,
                  accentColor: const Color(0xFFE11D48),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DescriptiveMetricsPanel(statistics: stats),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 920) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: StockHealthDonutChart(health: stats.stockHealth),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: CategoryBarChart(categories: stats.categories),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    StockHealthDonutChart(health: stats.stockHealth),
                    const SizedBox(height: 16),
                    CategoryBarChart(categories: stats.categories),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            MonthlyRotationChart(points: stats.monthlyRotation),
            const SizedBox(height: 20),
            _TopProductsCard(
              products: stats.topByValue,
              currency: currency,
              thousands: thousands,
            ),
          ],
        );
      },
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({
    required this.products,
    required this.currency,
    required this.thousands,
  });

  final List<TopProductStat> products;
  final NumberFormat currency;
  final NumberFormat thousands;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 10 Productos por Valor Inmovilizado',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Productos con mayor capital representado en almacén',
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
              const SizedBox(height: 16),
              if (products.isEmpty)
                const Text('Sin productos disponibles.')
              else
                ...products.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final item = entry.value;
                  final catStyle =
                      ProductCategoryHelper.styleFor(item.category);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F2B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: catStyle.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: catStyle.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.sku} · ${item.category} · ${thousands.format(item.stock)} uds. × ${currency.format(item.unitCost)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currency.format(item.totalValue),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
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

