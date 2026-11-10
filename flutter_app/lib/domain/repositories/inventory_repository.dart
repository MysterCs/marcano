import '../../data/models/descriptive_statistics.dart';
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

  Future<DescriptiveStatistics> getDescriptiveStatistics({
    String? category,
  }) async {
    final products = await listProducts();
    return DescriptiveStatistics.fromProducts(products);
  }

  Future<List<int>> exportStatistics({
    required String format,
    String? category,
  }) async =>
      const [];

  Future<int> reclassifyCategories() async => 0;
}
