import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marcano_flutter/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('La pantalla inicial muestra el inventario autenticado', (
    tester,
  ) async {
    final auth = AuthTestFixture(initialToken: 'saved-token');
    await auth.controller.restore();

    await tester.pumpWidget(
      MarcanoApp(
        repository: const FakeInventoryRepository(),
        apiClient: auth.apiClient,
        authController: auth.controller,
        rateRepository: const FakeRateRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcano Inventario'), findsOneWidget);
    expect(find.text('Producto demo'), findsOneWidget);
    expect(find.text('8 uds.'), findsOneWidget);
    expect(auth.storage.token, 'saved-token');

    // Navegar a Estadísticas Descriptivas
    await tester.tap(find.text('Estadísticas'));
    await tester.pumpAndSettle();
    expect(find.text('Estadísticas Descriptivas'), findsOneWidget);

    // Navegar a Ajustes (debe mostrar General de manera predeterminada)
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('general_section')), findsOneWidget);
  });
}
