import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marcano_flutter/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('El usuario puede iniciar sesion y cerrarla', (tester) async {
    final auth = AuthTestFixture();
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

    expect(find.text('Bienvenido'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V-001');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pumpAndSettle();

    expect(find.text('Producto demo'), findsOneWidget);
    expect(auth.storage.token, 'test-token');

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(auth.storage.token, isNull);
  });

  testWidgets('El registro crea la cuenta e inicia la sesion', (tester) async {
    final auth = AuthTestFixture();
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

    await tester.tap(find.text('Crea una cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Usuario Demo');
    await tester.enterText(fields.at(1), 'V-001');
    await tester.enterText(fields.at(2), '123');
    await tester.enterText(fields.at(3), '123');
    await tester.ensureVisible(find.text('Crear cuenta e ingresar'));
    await tester.tap(find.text('Crear cuenta e ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Producto demo'), findsOneWidget);
    expect(auth.storage.token, 'test-token');
  });

  testWidgets('El acceso valida el minimo de tres caracteres', (tester) async {
    final auth = AuthTestFixture();
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

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V-001');
    await tester.enterText(fields.at(1), '12');
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pump();

    expect(
      find.text('La contrasena debe tener al menos 3 caracteres.'),
      findsOneWidget,
    );
    expect(auth.storage.token, isNull);
  });
}
