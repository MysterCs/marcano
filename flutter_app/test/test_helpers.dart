import 'package:marcano_flutter/core/auth/auth_controller.dart';
import 'package:marcano_flutter/data/models/auth_session.dart';
import 'package:marcano_flutter/data/models/auth_user.dart';
import 'package:marcano_flutter/data/models/currency.dart';
import 'package:marcano_flutter/data/models/descriptive_statistics.dart';
import 'package:marcano_flutter/data/models/dollar_rate.dart';
import 'package:marcano_flutter/data/models/inventory_summary.dart';
import 'package:marcano_flutter/data/models/product.dart';
import 'package:marcano_flutter/data/models/projection_point.dart';
import 'package:marcano_flutter/data/services/api_client.dart';
import 'package:marcano_flutter/data/services/session_storage.dart';
import 'package:marcano_flutter/domain/repositories/auth_repository.dart';
import 'package:marcano_flutter/domain/repositories/inventory_repository.dart';
import 'package:marcano_flutter/domain/repositories/rate_repository.dart';

class FakeInventoryRepository implements InventoryRepository {
  const FakeInventoryRepository();

  @override
  Future<InventorySummary> getSummary() async => const InventorySummary(
        products: 1,
        units: 8,
        lowStock: 0,
        inventoryValue: 80,
      );

  @override
  Future<List<Product>> listProducts() async => const [
        Product(
          id: 1,
          sku: 'DEMO-001',
          name: 'Producto demo',
          stock: 8,
          minStock: 2,
          unitCost: 10,
          salePrice: 15,
        ),
      ];

  @override
  Future<Product> updateProduct({
    required int productId,
    required Map<String, dynamic> changes,
  }) async =>
      const Product(
        id: 1,
        sku: 'DEMO-001',
        name: 'Producto demo',
        stock: 8,
        minStock: 2,
        unitCost: 10,
        salePrice: 15,
        updatedByUserId: 1,
        updatedByUserName: 'Usuario Demo',
      );

  @override
  Future<List<ProjectionPoint>> project({
    required int productId,
    required String movement,
    required int periods,
    required String strategy,
  }) async =>
      [];

  @override
  Future<DescriptiveStatistics> getDescriptiveStatistics({
    String? category,
  }) async {
    final products = await listProducts();
    return DescriptiveStatistics.fromProducts(products);
  }

  @override
  Future<List<int>> exportStatistics({
    required String format,
    String? category,
  }) async =>
      const [1, 2, 3];

  @override
  Future<int> reclassifyCategories() async => 1;
}

class FakeRateRepository implements RateRepository {
  const FakeRateRepository({this.rateValue = 897.54});

  final double rateValue;

  @override
  Future<DollarRate?> current() async =>
      DollarRate(value: rateValue, source: 'BCV');

  @override
  Future<DollarRate> refreshFromBcv() async =>
      DollarRate(value: rateValue, source: 'BCV', updatedAt: DateTime(2026));

  @override
  Future<DollarRate> setManualRate(double value) async =>
      DollarRate(value: value, source: 'manual', updatedAt: DateTime(2026));

  @override
  Future<List<BcvCurrency>> bcvCurrencies() async => const [
        BcvCurrency(name: 'Dolar', value: 897.54),
        BcvCurrency(name: 'Euro', value: 1001.19),
        BcvCurrency(name: 'Yuan', value: 134.45),
      ];

  @override
  Future<List<AlternateCurrency>> alternates() async => const [
        AlternateCurrency(
          id: 1,
          name: 'Euro',
          value: 1001.19,
          source: 'bcv',
          updatedAt: null,
        ),
      ];

  @override
  Future<List<AlternateCurrency>> setAlternates(
    List<Map<String, dynamic>> items,
  ) async =>
      const [
        AlternateCurrency(
          id: 1,
          name: 'Euro',
          value: 1001.19,
          source: 'bcv',
          updatedAt: null,
        ),
      ];

  @override
  Future<AlternateCurrency> updateAlternate(int id, double value) async =>
      AlternateCurrency(
        id: id,
        name: 'Euro',
        value: value,
        source: 'manual',
        updatedAt: null,
      );

  @override
  Future<void> deleteAlternate(int id) async {}
}

class FakeAuthRepository implements AuthRepository {
  static const user = AuthUser(
    id: 1,
    fullName: 'Usuario Demo',
    cedula: 'V-001',
  );

  @override
  Future<AuthUser> register({
    required String fullName,
    required String cedula,
    required String password,
  }) async =>
      AuthUser(id: 1, fullName: fullName, cedula: cedula);

  @override
  Future<AuthSession> login({
    required String cedula,
    required String password,
  }) async =>
      const AuthSession(accessToken: 'test-token', user: user);

  @override
  Future<AuthUser> me() async => user;
}

class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this.token]);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;
}

class AuthTestFixture {
  AuthTestFixture({String? initialToken}) {
    storage = MemorySessionStorage(initialToken);
    apiClient = ApiClient(baseUrl: 'http://localhost');
    controller = AuthController(
      authRepository: FakeAuthRepository(),
      sessionStorage: storage,
      apiClient: apiClient,
    );
  }

  late final MemorySessionStorage storage;
  late final ApiClient apiClient;
  late final AuthController controller;
}
