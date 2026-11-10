import 'package:flutter/material.dart';

import '../../core/categories/product_category_helper.dart';
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
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  String _selectedCategory = 'Todas';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferencesChanged);
    _data = _load();
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_onPreferencesChanged);
    _searchController.dispose();
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

  List<Product> _filterProducts(List<Product> all) {
    final q = _searchQuery.trim().toLowerCase();
    return all.where((p) {
      if (_selectedCategory != 'Todas' && p.category != _selectedCategory) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        final matchModel = (p.model ?? '').toLowerCase().contains(q);
        final matchCat = p.category.toLowerCase().contains(q);
        if (!matchName && !matchSku && !matchModel && !matchCat) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
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
          final filtered = _filterProducts(data.products);
          final pageSize = widget.preferences.pageSize;
          final totalPages =
              (filtered.length / pageSize).ceil().clamp(1, 1 << 31);
          final page = _currentPage.clamp(0, totalPages - 1);
          final start = page * pageSize;
          final end = start + pageSize;
          final visibleProducts = filtered.isEmpty
              ? const <Product>[]
              : filtered.sublist(
                  start,
                  end > filtered.length ? filtered.length : end,
                );

          final categoryCounts = <String, int>{'Todas': data.products.length};
          for (final p in data.products) {
            categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
          }
          final categories = [
            'Todas',
            ...ProductCategoryHelper.allCategories
                .where((c) => (categoryCounts[c] ?? 0) > 0),
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resumen de Inventario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DashboardSummaryGrid(summary: data.summary),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Productos (${filtered.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                }),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar por nombre, SKU, modelo o categoría...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 0;
                            });
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
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
                                color: ProductCategoryHelper.styleFor(
                                  categories[i],
                                ).color,
                              ),
                        label: Text(
                          '${categories[i]} (${categoryCounts[categories[i]] ?? 0})',
                        ),
                        selected: _selectedCategory == categories[i],
                        onSelected: (_) => setState(() {
                          _selectedCategory = categories[i];
                          _currentPage = 0;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (data.products.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        Text('Todavia no hay productos. Crealos desde la API.'),
                  ),
                )
              else if (visibleProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se encontraron productos con los filtros seleccionados.',
                    ),
                  ),
                )
              else
                ...visibleProducts.map(
                  (product) => ProductCard(
                    product: product,
                    onOpenInfo: () => _openProduct(product),
                  ),
                ),
              if (filtered.isNotEmpty) ...[
                const SizedBox(height: 12),
                PaginationBar(
                  currentPage: page,
                  totalPages: totalPages,
                  totalItems: filtered.length,
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
