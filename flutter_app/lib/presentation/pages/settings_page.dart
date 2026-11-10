import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../data/services/api_client.dart';
import '../../data/services/app_preferences.dart';
import '../../domain/repositories/inventory_repository.dart';
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
    this.inventoryRepository,
    super.key,
  });

  final AuthController authController;
  final ApiClient apiClient;
  final RateRepository rateRepository;
  final AppPreferences preferences;
  final InventoryRepository? inventoryRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Predeterminado en 0: General
  int _selectedSubmenuIndex = 0;

  static const List<_SubmenuSpec> _submenus = [
    _SubmenuSpec(
      label: 'General',
      subtitle: 'Estado del sistema y cuenta activa',
      icon: Icons.tune_rounded,
      color: Color(0xFF3B82F6),
    ),
    _SubmenuSpec(
      label: 'Inventario',
      subtitle: 'Paginación y categorías de productos',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFFF97316),
    ),
    _SubmenuSpec(
      label: 'Tasa y Divisas',
      subtitle: 'Tasa BCV y monedas alternas',
      icon: Icons.currency_exchange_rounded,
      color: Color(0xFFE11D48),
    ),
  ];

  Widget _buildActiveSubsection() {
    switch (_selectedSubmenuIndex) {
      case 1:
        return ListView(
          key: const ValueKey('inventario_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader(
              'Inventario',
              icon: Icons.inventory_2_outlined,
            ),
            InventorySettingsSection(
              preferences: widget.preferences,
              repository: widget.inventoryRepository,
            ),
          ],
        );
      case 2:
        return ListView(
          key: const ValueKey('tasa_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader(
              'Tasa y Divisas',
              icon: Icons.currency_exchange_rounded,
            ),
            RateSettingsSection(rateRepository: widget.rateRepository),
            const SizedBox(height: 16),
            AlternateCurrenciesSection(rateRepository: widget.rateRepository),
          ],
        );
      case 0:
      default:
        return ListView(
          key: const ValueKey('general_section'),
          padding: const EdgeInsets.all(16),
          children: [
            const SettingsGroupHeader(
              'General',
              icon: Icons.settings_outlined,
            ),
            SystemStatusSection(apiClient: widget.apiClient),
            const SizedBox(height: 16),
            AccountSection(authController: widget.authController),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 280,
                  margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A38)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          'Ajustes del Sistema',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _submenus.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _SubmenuTile(
                          spec: _submenus[i],
                          selected: _selectedSubmenuIndex == i,
                          onTap: () =>
                              setState(() => _selectedSubmenuIndex = i),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildActiveSubsection(),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1F1F2B).withValues(alpha: 0.85),
                      const Color(0xFF14141C),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _submenus.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: Icon(
                            _submenus[i].icon,
                            size: 18,
                            color: _selectedSubmenuIndex == i
                                ? Colors.white
                                : _submenus[i].color,
                          ),
                          label: Text(_submenus[i].label),
                          selected: _selectedSubmenuIndex == i,
                          selectedColor: _submenus[i].color,
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
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildActiveSubsection(),
                ),
              ),
            ],
          );
        },
      );
}

class _SubmenuSpec {
  const _SubmenuSpec({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _SubmenuTile extends StatelessWidget {
  const _SubmenuTile({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _SubmenuSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? spec.color.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? spec.color.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, color: spec.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w600,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.chevron_right_rounded, color: spec.color, size: 20),
            ],
          ),
        ),
      );
}
