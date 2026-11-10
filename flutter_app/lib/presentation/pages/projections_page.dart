import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/models/projection_point.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../widgets/projections/product_selector.dart';
import '../widgets/projections/projection_criteria.dart';
import '../widgets/projections/projection_result_list.dart';

class ProjectionsPage extends StatefulWidget {
  const ProjectionsPage({required this.repository, super.key});

  final InventoryRepository repository;

  @override
  State<ProjectionsPage> createState() => _ProjectionsPageState();
}

class _ProjectionsPageState extends State<ProjectionsPage> {
  late Future<List<Product>> _products;
  Future<List<ProjectionPoint>>? _projection;
  int? _productId;
  String _movement = 'sale';
  String _strategy = 'moving_average';

  @override
  void initState() {
    super.initState();
    _products = widget.repository.listProducts();
  }

  void _calculate() {
    final productId = _productId;
    if (productId == null) return;
    setState(() {
      _projection = widget.repository.project(
        productId: productId,
        movement: _movement,
        periods: 6,
        strategy: _strategy,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text(
                    'No se pudieron cargar los productos: ${snapshot.error}');
              }
              final products = snapshot.requireData;
              if (products.isEmpty) {
                return const Text(
                    'Registra productos antes de calcular proyecciones.');
              }
              return ProductSelector(
                products: products,
                selectedId: _productId,
                onChanged: (value) => setState(() => _productId = value),
              );
            },
          ),
          const SizedBox(height: 16),
          ProjectionCriteria(
            movement: _movement,
            strategy: _strategy,
            onMovementChanged: (value) => setState(() => _movement = value),
            onStrategyChanged: (value) => setState(() => _strategy = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Proyectar 6 meses'),
          ),
          const SizedBox(height: 24),
          ProjectionResultList(projection: _projection),
        ],
      );
}
