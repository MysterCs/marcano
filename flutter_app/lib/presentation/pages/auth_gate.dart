import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../data/services/api_client.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/rate_repository.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.authController,
    required this.repository,
    required this.rateRepository,
    required this.apiClient,
    super.key,
  });

  final AuthController authController;
  final InventoryRepository repository;
  final RateRepository rateRepository;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          switch (authController.status) {
            case AuthStatus.initializing:
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Colors.indigo,
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              );
            case AuthStatus.authenticated:
              return HomePage(
                repository: repository,
                rateRepository: rateRepository,
                authController: authController,
                apiClient: apiClient,
              );
            case AuthStatus.unauthenticated:
              return LoginPage(authController: authController);
          }
        },
      );
}
