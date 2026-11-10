import 'package:flutter/material.dart';

import '../../../data/services/app_preferences.dart';
import 'settings_section.dart';

/// Subseccion de ajustes de inventario: densidad del listado.
class InventorySettingsSection extends StatelessWidget {
  const InventorySettingsSection({required this.preferences, super.key});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: 'Inventario',
        icon: Icons.inventory_2_outlined,
        children: [
          Text('Productos por pagina', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: preferences,
            builder: (context, _) => SegmentedButton<int>(
              segments: [
                for (final option in AppPreferences.pageSizeOptions)
                  ButtonSegment(value: option, label: Text('$option')),
              ],
              selected: {preferences.pageSize},
              onSelectionChanged: (selection) {
                final value = selection.first;
                preferences.setPageSize(value);
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
      );
}
