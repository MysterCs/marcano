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
  });
}
