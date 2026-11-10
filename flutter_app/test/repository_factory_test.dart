import 'package:flutter_test/flutter_test.dart';
import 'package:marcano_flutter/core/factories/repository_factory.dart';
import 'package:marcano_flutter/data/repositories/remote_inventory_repository.dart';

void main() {
  test('RepositoryFactory crea el repositorio remoto por defecto', () {
    final repository = RepositoryFactory.create();

    expect(repository, isA<RemoteInventoryRepository>());
  });
}
