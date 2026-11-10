import 'package:flutter/material.dart';

import '../../../data/models/product.dart';

/// Encabezado del widget de producto: identificacion y boton de cierre.
class ProductInfoHeader extends StatelessWidget {
  const ProductInfoHeader({
    required this.product,
    required this.onClose,
    super.key,
  });

  final Product product;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(
            product.hasLowStock ? Icons.warning_amber : Icons.inventory_2,
            color: product.hasLowStock ? colorScheme.secondary : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'SKU ${product.sku} · ID ${product.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
