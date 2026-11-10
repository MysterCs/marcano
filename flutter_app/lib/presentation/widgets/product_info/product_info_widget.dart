import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/product.dart';
import '../../../domain/repositories/inventory_repository.dart';
import 'audit_info_card.dart';
import 'product_info_form.dart';
import 'product_info_header.dart';

/// Widget con la informacion del producto. Permite editar y guardar
/// los cambios en la base de datos mediante la API.
class ProductInfoWidget extends StatefulWidget {
  const ProductInfoWidget({
    required this.product,
    required this.repository,
    super.key,
  });

  final Product product;
  final InventoryRepository repository;

  static DateFormat get dateFormat => DateFormat('dd/MM/yyyy HH:mm');

  @override
  State<ProductInfoWidget> createState() => _ProductInfoWidgetState();
}

class _ProductInfoWidgetState extends State<ProductInfoWidget> {
  late final ProductInfoFormControllers _controllers;
  late bool _isActive;
  late String _category;
  bool _saving = false;
  bool _editing = false;
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controllers = ProductInfoFormControllers.fromProduct(widget.product);
    _isActive = widget.product.isActive;
    _category = widget.product.category;
  }

  Map<String, dynamic> _collectChanges() => {
        'name': _controllers.name.text.trim(),
        'category': _category,
        'model': _controllers.model.text.trim(),
        'stock': int.tryParse(_controllers.stock.text) ?? 0,
        'min_stock': int.tryParse(_controllers.minStock.text) ?? 0,
        'point': int.tryParse(_controllers.point.text) ?? 0,
        'unit': _controllers.unit.text.trim(),
        'is_active': _isActive,
        'unit_cost':
            double.tryParse(_controllers.unitCost.text.replaceAll(',', '.')) ??
                0,
        'sale_price': double.tryParse(
                _controllers.salePrice.text.replaceAll(',', '.')) ??
            0,
      };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.repository.updateProduct(
        productId: widget.product.id,
        changes: _collectChanges(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.updatedByUserName == null
                ? 'Producto actualizado.'
                : 'Producto actualizado por ${updated.updatedByUserName}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              ProductInfoHeader(
                product: widget.product,
                onClose: () => Navigator.of(context).pop(false),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuditInfoCard(
                        product: widget.product,
                        format: ProductInfoWidget.dateFormat,
                      ),
                      const SizedBox(height: 16),
                      ProductInfoForm(
                        name: _controllers.name,
                        category: _category,
                        model: _controllers.model,
                        stock: _controllers.stock,
                        minStock: _controllers.minStock,
                        point: _controllers.point,
                        unit: _controllers.unit,
                        unitCost: _controllers.unitCost,
                        salePrice: _controllers.salePrice,
                        isActive: _isActive,
                        editing: _editing,
                        formKey: _formKey,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
                        onCategoryChanged: (value) =>
                            setState(() => _category = value),
                      ),
                      const SizedBox(height: 20),
                      if (_editing)
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Guardar cambios'),
                        ),
                      if (!_editing)
                        FilledButton.icon(
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar informacion'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }
}

/// Controladores de los campos del formulario de producto.
class ProductInfoFormControllers {
  ProductInfoFormControllers({
    required this.name,
    required this.model,
    required this.stock,
    required this.minStock,
    required this.point,
    required this.unit,
    required this.unitCost,
    required this.salePrice,
  });

  factory ProductInfoFormControllers.fromProduct(Product product) =>
      ProductInfoFormControllers(
        name: TextEditingController(text: product.name),
        model: TextEditingController(text: product.model ?? ''),
        stock: TextEditingController(text: '${product.stock}'),
        minStock: TextEditingController(text: '${product.minStock}'),
        point: TextEditingController(text: '${product.point}'),
        unit: TextEditingController(text: product.unit),
        unitCost: TextEditingController(text: product.unitCost.toString()),
        salePrice: TextEditingController(text: product.salePrice.toString()),
      );

  final TextEditingController name;
  final TextEditingController model;
  final TextEditingController stock;
  final TextEditingController minStock;
  final TextEditingController point;
  final TextEditingController unit;
  final TextEditingController unitCost;
  final TextEditingController salePrice;

  void dispose() {
    name.dispose();
    model.dispose();
    stock.dispose();
    minStock.dispose();
    point.dispose();
    unit.dispose();
    unitCost.dispose();
    salePrice.dispose();
  }
}
