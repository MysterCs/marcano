class InventorySummary {
  const InventorySummary({
    required this.products,
    required this.units,
    required this.lowStock,
    required this.inventoryValue,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) =>
      InventorySummary(
        products: json['products'] as int,
        units: json['units'] as int,
        lowStock: json['low_stock'] as int,
        inventoryValue: (json['inventory_value'] as num).toDouble(),
      );

  final int products;
  final int units;
  final int lowStock;
  final double inventoryValue;
}
