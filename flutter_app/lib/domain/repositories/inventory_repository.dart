import '../../data/models/inventory_summary.dart';
import '../../data/models/product.dart';
import '../../data/models/projection_point.dart';

abstract interface class InventoryRepository {
  Future<List<Product>> listProducts();

  Future<InventorySummary> getSummary();

  Future<List<ProjectionPoint>> project({
    required int productId,
    required String movement,
    required int periods,
    required String strategy,
  });

  Future<Product> updateProduct({
    required int productId,
    required Map<String, dynamic> changes,
  });
}
