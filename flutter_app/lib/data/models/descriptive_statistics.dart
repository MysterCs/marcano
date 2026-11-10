import 'dart:math' as math;

import 'product.dart';

class MetricDistribution {
  const MetricDistribution({
    required this.mean,
    required this.median,
    required this.mode,
    required this.stdDev,
    required this.variance,
    required this.minimum,
    required this.maximum,
    required this.p25,
    required this.p75,
    required this.p90,
    required this.iqr,
    required this.cv,
  });

  factory MetricDistribution.fromJson(Map<String, dynamic> json) =>
      MetricDistribution(
        mean: (json['mean'] as num).toDouble(),
        median: (json['median'] as num).toDouble(),
        mode: (json['mode'] as num).toDouble(),
        stdDev: (json['std_dev'] as num).toDouble(),
        variance: (json['variance'] as num).toDouble(),
        minimum: (json['minimum'] as num).toDouble(),
        maximum: (json['maximum'] as num).toDouble(),
        p25: (json['p25'] as num).toDouble(),
        p75: (json['p75'] as num).toDouble(),
        p90: (json['p90'] as num).toDouble(),
        iqr: (json['iqr'] as num).toDouble(),
        cv: (json['cv'] as num).toDouble(),
      );

  factory MetricDistribution.fromValues(List<double> raw) {
    if (raw.isEmpty) {
      return const MetricDistribution(
        mean: 0,
        median: 0,
        mode: 0,
        stdDev: 0,
        variance: 0,
        minimum: 0,
        maximum: 0,
        p25: 0,
        p75: 0,
        p90: 0,
        iqr: 0,
        cv: 0,
      );
    }
    final sorted = [...raw]..sort();
    final n = sorted.length;
    final mean = sorted.reduce((a, b) => a + b) / n;
    final variance =
        sorted.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(variance);

    double percentile(double p) {
      final pos = (n - 1) * p;
      final lower = pos.floor();
      final upper = pos.ceil();
      if (lower == upper) return sorted[lower];
      return sorted[lower] + (sorted[upper] - sorted[lower]) * (pos - lower);
    }

    final median = percentile(0.5);
    final p25 = percentile(0.25);
    final p75 = percentile(0.75);
    final p90 = percentile(0.90);

    final counts = <double, int>{};
    for (final v in sorted) {
      final key = (v * 100).round() / 100;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    var mode = sorted.first;
    var bestCount = 0;
    counts.forEach((k, c) {
      if (c > bestCount) {
        bestCount = c;
        mode = k;
      }
    });

    return MetricDistribution(
      mean: mean,
      median: median,
      mode: mode,
      stdDev: stdDev,
      variance: variance,
      minimum: sorted.first,
      maximum: sorted.last,
      p25: p25,
      p75: p75,
      p90: p90,
      iqr: p75 - p25,
      cv: mean > 0 ? (stdDev / mean * 100) : 0,
    );
  }

  final double mean;
  final double median;
  final double mode;
  final double stdDev;
  final double variance;
  final double minimum;
  final double maximum;
  final double p25;
  final double p75;
  final double p90;
  final double iqr;
  final double cv;
}

class StockHealthSummary {
  const StockHealthSummary({
    required this.optimalCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inactiveCount,
  });

  factory StockHealthSummary.fromJson(Map<String, dynamic> json) =>
      StockHealthSummary(
        optimalCount: json['optimal_count'] as int,
        lowStockCount: json['low_stock_count'] as int,
        outOfStockCount: json['out_of_stock_count'] as int,
        inactiveCount: json['inactive_count'] as int,
      );

  final int optimalCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int inactiveCount;
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.productCount,
    required this.totalUnits,
    required this.totalValue,
    required this.sharePercentage,
    required this.lowStockCount,
    required this.avgStock,
    required this.avgUnitCost,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        category: json['category'] as String,
        productCount: json['product_count'] as int,
        totalUnits: json['total_units'] as int,
        totalValue: (json['total_value'] as num).toDouble(),
        sharePercentage: (json['share_percentage'] as num).toDouble(),
        lowStockCount: json['low_stock_count'] as int,
        avgStock: (json['avg_stock'] as num).toDouble(),
        avgUnitCost: (json['avg_unit_cost'] as num).toDouble(),
      );

  final String category;
  final int productCount;
  final int totalUnits;
  final double totalValue;
  final double sharePercentage;
  final int lowStockCount;
  final double avgStock;
  final double avgUnitCost;
}

class TopProductStat {
  const TopProductStat({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.stock,
    required this.unitCost,
    required this.totalValue,
  });

  factory TopProductStat.fromJson(Map<String, dynamic> json) => TopProductStat(
        id: json['id'] as int,
        sku: json['sku'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        stock: json['stock'] as int,
        unitCost: (json['unit_cost'] as num).toDouble(),
        totalValue: (json['total_value'] as num).toDouble(),
      );

  final int id;
  final String sku;
  final String name;
  final String category;
  final int stock;
  final double unitCost;
  final double totalValue;
}

class MonthlyRotationPoint {
  const MonthlyRotationPoint({
    required this.period,
    required this.entries,
    required this.exits,
  });

  factory MonthlyRotationPoint.fromJson(Map<String, dynamic> json) =>
      MonthlyRotationPoint(
        period: json['period'] as String,
        entries: (json['entries'] as num).toDouble(),
        exits: (json['exits'] as num).toDouble(),
      );

  final String period;
  final double entries;
  final double exits;
}

class DescriptiveStatistics {
  const DescriptiveStatistics({
    required this.totalProducts,
    required this.totalUnits,
    required this.totalInventoryValue,
    required this.activeCategories,
    required this.stockDistribution,
    required this.costDistribution,
    required this.valueDistribution,
    required this.stockHealth,
    required this.categories,
    required this.topByValue,
    required this.topByStock,
    required this.monthlyRotation,
  });

  factory DescriptiveStatistics.fromJson(Map<String, dynamic> json) =>
      DescriptiveStatistics(
        totalProducts: json['total_products'] as int,
        totalUnits: json['total_units'] as int,
        totalInventoryValue: (json['total_inventory_value'] as num).toDouble(),
        activeCategories: json['active_categories'] as int,
        stockDistribution: MetricDistribution.fromJson(
          json['stock_distribution'] as Map<String, dynamic>,
        ),
        costDistribution: MetricDistribution.fromJson(
          json['cost_distribution'] as Map<String, dynamic>,
        ),
        valueDistribution: MetricDistribution.fromJson(
          json['value_distribution'] as Map<String, dynamic>,
        ),
        stockHealth: StockHealthSummary.fromJson(
          json['stock_health'] as Map<String, dynamic>,
        ),
        categories: (json['categories'] as List<dynamic>)
            .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        topByValue: (json['top_by_value'] as List<dynamic>)
            .map((e) => TopProductStat.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        topByStock: (json['top_by_stock'] as List<dynamic>)
            .map((e) => TopProductStat.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        monthlyRotation: (json['monthly_rotation'] as List<dynamic>)
            .map((e) => MonthlyRotationPoint.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  factory DescriptiveStatistics.fromProducts(List<Product> products) {
    final stocks = products.map((p) => p.stock.toDouble()).toList();
    final costs = products.map((p) => p.unitCost).toList();
    final values = products.map((p) => p.stock * p.unitCost).toList();
    final totalValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b);

    final byCategory = <String, List<Product>>{};
    for (final p in products) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    final categories = byCategory.entries.map((entry) {
      final items = entry.value;
      final units = items.fold<int>(0, (sum, p) => sum + p.stock);
      final val = items.fold<double>(0, (sum, p) => sum + p.stock * p.unitCost);
      final low = items.where((p) => p.hasLowStock).length;
      return CategoryStat(
        category: entry.key,
        productCount: items.length,
        totalUnits: units,
        totalValue: val,
        sharePercentage: totalValue > 0 ? (val / totalValue * 100) : 0,
        lowStockCount: low,
        avgStock: items.isEmpty ? 0 : units / items.length,
        avgUnitCost: items.isEmpty
            ? 0
            : items.fold<double>(0, (s, p) => s + p.unitCost) / items.length,
      );
    }).toList()
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

    final topVal = [...products]
      ..sort((a, b) => (b.stock * b.unitCost).compareTo(a.stock * a.unitCost));
    final topStk = [...products]..sort((a, b) => b.stock.compareTo(a.stock));

    return DescriptiveStatistics(
      totalProducts: products.length,
      totalUnits: products.fold<int>(0, (s, p) => s + p.stock),
      totalInventoryValue: totalValue,
      activeCategories: categories.length,
      stockDistribution: MetricDistribution.fromValues(stocks),
      costDistribution: MetricDistribution.fromValues(costs),
      valueDistribution: MetricDistribution.fromValues(values),
      stockHealth: StockHealthSummary(
        optimalCount:
            products.where((p) => p.isActive && p.stock > p.minStock).length,
        lowStockCount: products
            .where((p) => p.isActive && p.stock > 0 && p.stock <= p.minStock)
            .length,
        outOfStockCount:
            products.where((p) => p.isActive && p.stock == 0).length,
        inactiveCount: products.where((p) => !p.isActive).length,
      ),
      categories: categories,
      topByValue: topVal
          .take(10)
          .map(
            (p) => TopProductStat(
              id: p.id,
              sku: p.sku,
              name: p.name,
              category: p.category,
              stock: p.stock,
              unitCost: p.unitCost,
              totalValue: p.stock * p.unitCost,
            ),
          )
          .toList(),
      topByStock: topStk
          .take(10)
          .map(
            (p) => TopProductStat(
              id: p.id,
              sku: p.sku,
              name: p.name,
              category: p.category,
              stock: p.stock,
              unitCost: p.unitCost,
              totalValue: p.stock * p.unitCost,
            ),
          )
          .toList(),
      monthlyRotation: const [],
    );
  }

  final int totalProducts;
  final int totalUnits;
  final double totalInventoryValue;
  final int activeCategories;
  final MetricDistribution stockDistribution;
  final MetricDistribution costDistribution;
  final MetricDistribution valueDistribution;
  final StockHealthSummary stockHealth;
  final List<CategoryStat> categories;
  final List<TopProductStat> topByValue;
  final List<TopProductStat> topByStock;
  final List<MonthlyRotationPoint> monthlyRotation;
}

