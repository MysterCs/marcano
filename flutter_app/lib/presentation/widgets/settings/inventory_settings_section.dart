import 'package:flutter/material.dart';

import '../../../core/categories/product_category_helper.dart';
import '../../../data/services/app_preferences.dart';
import '../../../domain/repositories/inventory_repository.dart';
import 'settings_section.dart';

/// Subseccion de ajustes de inventario: densidad del listado y categorias.
class InventorySettingsSection extends StatefulWidget {
  const InventorySettingsSection({
    required this.preferences,
    this.repository,
    super.key,
  });

  final AppPreferences preferences;
  final InventoryRepository? repository;

  @override
  State<InventorySettingsSection> createState() =>
      _InventorySettingsSectionState();
}

class _InventorySettingsSectionState extends State<InventorySettingsSection> {
  bool _reclassifying = false;

  Future<void> _reclassify() async {
    final repo = widget.repository;
    if (repo == null) return;
    setState(() => _reclassifying = true);
    try {
      final updated = await repo.reclassifyCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clasificación automática completada ($updated productos actualizados).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo reclasificar: $error')),
      );
    } finally {
      if (mounted) setState(() => _reclassifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SettingsSection(
            title: 'Paginación del listado',
            icon: Icons.inventory_2_outlined,
            children: [
              Text(
                'Productos por pagina',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: widget.preferences,
                builder: (context, _) => SegmentedButton<int>(
                  segments: [
                    for (final option in AppPreferences.pageSizeOptions)
                      ButtonSegment(value: option, label: Text('$option')),
                  ],
                  selected: {widget.preferences.pageSize},
                  onSelectionChanged: (selection) {
                    final value = selection.first;
                    widget.preferences.setPageSize(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$value productos por pagina.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define cuantos productos se muestran por pagina en el inventario.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Categorización automática por nombre',
            icon: Icons.category_outlined,
            children: [
              Text(
                'Los productos se agrupan automáticamente según palabras clave de su nombre en ${ProductCategoryHelper.allCategories.length} categorías:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductCategoryHelper.allCategories.map((cat) {
                  final style = ProductCategoryHelper.styleFor(cat);
                  return Chip(
                    avatar: Icon(style.icon, size: 16, color: style.color),
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    backgroundColor: style.color.withValues(alpha: 0.12),
                    side: BorderSide(color: style.color.withValues(alpha: 0.35)),
                  );
                }).toList(),
              ),
              if (widget.repository != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _reclassifying ? null : _reclassify,
                  icon: _reclassifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Reclasificar productos según su nombre'),
                ),
              ],
            ],
          ),
        ],
      );
}
