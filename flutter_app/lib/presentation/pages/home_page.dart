import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../data/services/api_client.dart';
import '../../data/services/app_preferences.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/rate_repository.dart';
import '../widgets/home/home_nav_bar.dart';
import '../widgets/rate/system_rate_badge.dart';
import 'dashboard_page.dart';
import 'projections_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.repository,
    required this.rateRepository,
    required this.authController,
    required this.apiClient,
    super.key,
  });

  final InventoryRepository repository;
  final RateRepository rateRepository;
  final AuthController authController;
  final ApiClient apiClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppPreferences _preferences;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _preferences = AppPreferences()..load();
  }

  List<Widget> get _pages => [
        DashboardPage(
          repository: widget.repository,
          preferences: _preferences,
        ),
        StatisticsPage(repository: widget.repository),
        ProjectionsPage(repository: widget.repository),
        SettingsPage(
          authController: widget.authController,
          apiClient: widget.apiClient,
          rateRepository: widget.rateRepository,
          preferences: _preferences,
          inventoryRepository: widget.repository,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Marcano Inventario'),
          ],
        ),
        actions: [
          SystemRateBadge(rateRepository: widget.rateRepository),
          IconButton(
            onPressed: () => widget.authController.logout(),
            icon: const Icon(Icons.logout),
            tooltip:
                'Cerrar sesion (${widget.authController.user?.fullName ?? ''})',
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: HomeNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}
