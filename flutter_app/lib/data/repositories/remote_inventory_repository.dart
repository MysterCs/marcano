import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_summary.dart';
import '../models/product.dart';
import '../models/projection_point.dart';
import '../services/api_client.dart';

class RemoteInventoryRepository implements InventoryRepository {
  const RemoteInventoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Product>> listProducts() async {
    final response = await _apiClient.getJson('/api/products') as List<dynamic>;
    return response
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<InventorySummary> getSummary() async {
    final response = await _apiClient.getJson('/api/inventory/summary');
    return InventorySummary.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<ProjectionPoint>> project({
    required int productId,
    required String movement,
    required int periods,
    required String strategy,
  }) async {
    final response = await _apiClient.getJson(
      '/api/projections/$productId',
      queryParameters: {
        'movement': movement,
        'periods': '$periods',
        'strategy': strategy,
      },
    ) as List<dynamic>;
    return response
        .map((item) => ProjectionPoint.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Product> updateProduct({
    required int productId,
    required Map<String, dynamic> changes,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/products/$productId',
      changes,
    ) as Map<String, dynamic>;
    return Product.fromJson(response);
  }
}
