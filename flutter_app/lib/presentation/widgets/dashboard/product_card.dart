import 'package:flutter/material.dart';

import '../../../core/categories/product_category_helper.dart';
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
    final categoryStyle = ProductCategoryHelper.styleFor(product.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (product.hasLowStock
                    ? colorScheme.secondary
                    : categoryStyle.color)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            product.hasLowStock ? Icons.warning_amber : categoryStyle.icon,
            color: product.hasLowStock
                ? colorScheme.secondary
                : categoryStyle.color,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${product.sku} · Minimo ${product.minStock}'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryStyle.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: categoryStyle.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  product.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryStyle.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: product.hasLowStock
                    ? colorScheme.secondary.withValues(alpha: 0.16)
                    : const Color(0xFF1F1F2B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${product.stock} uds.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: product.hasLowStock ? colorScheme.secondary : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
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
