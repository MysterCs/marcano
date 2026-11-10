import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../data/services/api_client.dart';
import '../../data/services/app_preferences.dart';
import '../../domain/repositories/rate_repository.dart';
import '../widgets/settings/account_section.dart';
import '../widgets/settings/alternate_currencies_section.dart';
import '../widgets/settings/inventory_settings_section.dart';
import '../widgets/settings/rate_settings_section.dart';
import '../widgets/settings/settings_group_header.dart';
import '../widgets/settings/system_status_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.authController,
    required this.apiClient,
    required this.rateRepository,
    required this.preferences,
    super.key,
  });

  final AuthController authController;
  final ApiClient apiClient;
  final RateRepository rateRepository;
  final AppPreferences preferences;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedSubmenuIndex = 0; // 0: General, 1: Inventario, 2: Tasa y Divisas

  @override
  Widget build(BuildContext context) {
    final submenus = [
      {'label': 'General', 'icon': Icons.settings_outlined},
      {'label': 'Inventario', 'icon': Icons.inventory_2_outlined},
      {'label': 'Tasa y Divisas', 'icon': Icons.currency_exchange},
    ];

    Widget content;
    switch (_selectedSubmenuIndex) {
      case 1:
        content = ListView(
          key: const ValueKey('inventario_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader('Inventario', icon: Icons.inventory_2_outlined),
            InventorySettingsSection(preferences: widget.preferences),
          ],
        );
        break;
      case 2:
        content = ListView(
          key: const ValueKey('tasa_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader('Tasa', icon: Icons.currency_exchange),
            RateSettingsSection(rateRepository: widget.rateRepository),
            const SizedBox(height: 16),
            AlternateCurrenciesSection(rateRepository: widget.rateRepository),
          ],
        );
        break;
      case 0:
      default:
        content = ListView(
          key: const ValueKey('general_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader('General', icon: Icons.settings_outlined),
            SystemStatusSection(apiClient: widget.apiClient),
            const SizedBox(height: 16),
            AccountSection(authController: widget.authController),
          ],
        );
        break;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                for (int i = 0; i < submenus.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(
                      submenus[i]['icon'] as IconData,
                      size: 18,
                    ),
                    label: Text(submenus[i]['label'] as String),
                    selected: _selectedSubmenuIndex == i,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSubmenuIndex = i);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
