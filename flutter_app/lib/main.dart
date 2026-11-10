import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/auth/auth_controller.dart';
import 'core/factories/repository_factory.dart';
import 'data/services/api_client.dart';
import 'data/services/session_storage.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/rate_repository.dart';
import 'presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');

  final repositories = RepositoryFactory.createApp();
  final authController = AuthController(
    authRepository: repositories.auth,
    sessionStorage: const SecureSessionStorage(),
    apiClient: repositories.apiClient,
  );

  runApp(
    MarcanoApp(
      repository: repositories.inventory,
      rateRepository: repositories.rate,
      apiClient: repositories.apiClient,
      authController: authController,
    ),
  );
  unawaited(authController.restore());
}

class MarcanoApp extends StatelessWidget {
  const MarcanoApp({
    required this.repository,
    required this.rateRepository,
    required this.apiClient,
    required this.authController,
    super.key,
  });

  final InventoryRepository repository;
  final RateRepository rateRepository;
  final ApiClient apiClient;
  final AuthController authController;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Marcano Inventario',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: AuthGate(
          authController: authController,
          repository: repository,
          rateRepository: rateRepository,
          apiClient: apiClient,
        ),
      );

  static const _background = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF14141C);
  static const _surfaceVariant = Color(0xFF1F1F2B);
  static const _border = Color(0xFF2A2A38);
  static const _red = Color(0xFFE11D48);
  static const _orange = Color(0xFFF97316);
  static const _blue = Color(0xFF3B82F6);

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.dark(
      primary: _red,
      onPrimary: Colors.white,
      secondary: _orange,
      onSecondary: Colors.black,
      tertiary: _blue,
      onTertiary: Colors.white,
      surface: _surface,
      onSurface: const Color(0xFFE5E7EB),
      surfaceContainerHighest: _surfaceVariant,
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _blue,
          side: const BorderSide(color: _blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _surfaceVariant,
        contentTextStyle: TextStyle(color: Color(0xFFE5E7EB)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: _surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        modalBackgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red, width: 1.6),
        ),
      ),
    );
  }
}
