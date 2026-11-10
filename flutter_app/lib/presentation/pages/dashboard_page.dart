import 'package:flutter/material.dart';

import '../../data/models/inventory_summary.dart';
import '../../data/models/product.dart';
import '../../data/services/app_preferences.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../widgets/dashboard/dashboard_summary_grid.dart';
import '../widgets/dashboard/pagination_bar.dart';
import '../widgets/dashboard/product_card.dart';
import '../widgets/product_info/product_info_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.repository,
    required this.preferences,
    super.key,
  });

  final InventoryRepository repository;
  final AppPreferences preferences;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> _data;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferencesChanged);
    _data = _load();
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() => _refresh();

  Future<_DashboardData> _load() async {
    final summary = await widget.repository.getSummary();
    final products = await widget.repository.listProducts();
    return _DashboardData(summary, products);
  }

  void _refresh() => setState(() => _data = _load());

  void _goToPage(int page) => setState(() => _currentPage = page);

  Future<void> _openProduct(Product product) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductInfoWidget(
        product: product,
        repository: widget.repository,
      ),
    );
    if (saved ?? false) _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_DashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              error: '${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final data = snapshot.requireData;
          final pageSize = widget.preferences.pageSize;
          final totalPages =
              (data.products.length / pageSize).ceil().clamp(1, 1 << 31);
          final page = _currentPage.clamp(0, totalPages - 1);
          final start = page * pageSize;
          final end = start + pageSize;
          final visibleProducts = data.products.sublist(
            start,
            end > data.products.length ? data.products.length : end,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
              ),
              const SizedBox(height: 16),
              DashboardSummaryGrid(summary: data.summary),
              const SizedBox(height: 24),
              Text('Productos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (data.products.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        Text('Todavia no hay productos. Crealos desde la API.'),
                  ),
                )
              else
                ...visibleProducts.map(
                  (product) => ProductCard(
                    product: product,
                    onOpenInfo: () => _openProduct(product),
                  ),
                ),
              if (data.products.isNotEmpty) ...[
                const SizedBox(height: 12),
                PaginationBar(
                  currentPage: page,
                  totalPages: totalPages,
                  totalItems: data.products.length,
                  pageSize: pageSize,
                  onPageSelected: _goToPage,
                ),
              ],
            ],
          );
        },
      );
}

/// Vista de error cuando el dashboard no puede conectarse con la API.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo conectar con la API.'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

/// Estado cargado del dashboard.
class _DashboardData {
  const _DashboardData(this.summary, this.products);

  final InventorySummary summary;
  final List<Product> products;
}
