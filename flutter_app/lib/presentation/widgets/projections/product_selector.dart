import 'package:flutter/material.dart';

import '../../../data/models/product.dart';

/// Selector de producto para calcular proyecciones.
class ProductSelector extends StatelessWidget {
  const ProductSelector({
    required this.products,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<Product> products;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        initialValue: selectedId,
        decoration: const InputDecoration(labelText: 'Producto'),
        items: products
            .map(
              (product) => DropdownMenuItem<int>(
                value: product.id,
                child: Text(product.name),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      );
}
