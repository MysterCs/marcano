import 'package:flutter/material.dart';

import '../../../data/models/product.dart';

/// Tarjeta de producto del listado del dashboard.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onOpenInfo,
    super.key,
  });

  final Product product;
  final VoidCallback onOpenInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          product.hasLowStock ? Icons.warning_amber : Icons.inventory_2,
          color: product.hasLowStock ? colorScheme.secondary : null,
        ),
        title: Text(product.name),
        subtitle: Text('${product.sku} · Minimo ${product.minStock}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${product.stock} uds.'),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onOpenInfo,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ver y editar producto',
            ),
          ],
        ),
        onTap: onOpenInfo,
      ),
    );
  }
}
