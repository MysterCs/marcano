import 'package:flutter/material.dart';

import '../../../core/categories/product_category_helper.dart';

/// Seccion de campos editables del producto.
///
/// Recibe los controladores desde el widget orquestador y gestiona la
/// validacion de cada campo. No guarda: solo edita y valida.
class ProductInfoForm extends StatelessWidget {
  const ProductInfoForm({
    required this.name,
    required this.category,
    required this.model,
    required this.stock,
    required this.minStock,
    required this.point,
    required this.unit,
    required this.unitCost,
    required this.salePrice,
    required this.isActive,
    required this.editing,
    required this.formKey,
    required this.onActiveChanged,
    required this.onCategoryChanged,
    super.key,
  });

  final TextEditingController name;
  final String category;
  final TextEditingController model;
  final TextEditingController stock;
  final TextEditingController minStock;
  final TextEditingController point;
  final TextEditingController unit;
  final TextEditingController unitCost;
  final TextEditingController salePrice;
  final bool isActive;
  final bool editing;
  final GlobalKey<FormState> formKey;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String> onCategoryChanged;

  String? _validateRequired(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Campo obligatorio.' : null;

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Entero mayor o igual a 0.';
    return null;
  }

  String? _validateDecimal(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio.';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Valor mayor o igual a 0.';
    return null;
  }

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          children: [
            SwitchListTile(
              value: isActive,
              onChanged: editing ? onActiveChanged : null,
              title: const Text('Producto activo'),
              secondary: const Icon(Icons.toggle_on_outlined),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: name,
              readOnly: !editing,
              enabled: editing,
              validator: _validateRequired,
              onChanged: editing
                  ? (val) => onCategoryChanged(
                        ProductCategoryHelper.inferCategory(val),
                      )
                  : null,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  ProductCategoryHelper.allCategories.contains(category)
                      ? category
                      : ProductCategoryHelper.defaultCategory,
              onChanged: editing
                  ? (val) {
                      if (val != null) onCategoryChanged(val);
                    }
                  : null,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: ProductCategoryHelper.allCategories
                  .map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: model,
              readOnly: !editing,
              enabled: editing,
              decoration: const InputDecoration(labelText: 'Modelo'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stock,
                    readOnly: !editing,
                    enabled: editing,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                    decoration:
                        const InputDecoration(labelText: 'Existencias'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: minStock,
                    readOnly: !editing,
                    enabled: editing,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                    decoration:
                        const InputDecoration(labelText: 'Stock minimo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: point,
                    readOnly: !editing,
                    enabled: editing,
                    keyboardType: TextInputType.number,
                    validator: _validateNumber,
                    decoration: const InputDecoration(labelText: 'Punto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: unit,
                    readOnly: !editing,
                    enabled: editing,
                    validator: _validateRequired,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: unitCost,
                    readOnly: !editing,
                    enabled: editing,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: _validateDecimal,
                    decoration:
                        const InputDecoration(labelText: 'Coste unitario'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: salePrice,
                    readOnly: !editing,
                    enabled: editing,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: _validateDecimal,
                    decoration:
                        const InputDecoration(labelText: 'Precio de venta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
