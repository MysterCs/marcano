class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.stock,
    required this.minStock,
    required this.unitCost,
    required this.salePrice,
    this.model,
    this.point = 0,
    this.unit = 'UNI',
    this.isActive = true,
    this.updatedByUserId,
    this.updatedByUserName,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        sku: json['sku'] as String,
        name: json['name'] as String,
        stock: json['stock'] as int,
        minStock: json['min_stock'] as int,
        unitCost: (json['unit_cost'] as num).toDouble(),
        salePrice: (json['sale_price'] as num).toDouble(),
        model: json['model'] as String?,
        point: (json['point'] as num?)?.toInt() ?? 0,
        unit: (json['unit'] as String?) ?? 'UNI',
        isActive: (json['is_active'] as bool?) ?? true,
        updatedByUserId: json['updated_by_user_id'] as int?,
        updatedByUserName: json['updated_by_user_name'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.tryParse(json['updated_at'] as String),
      );

  final int id;
  final String sku;
  final String name;
  final int stock;
  final int minStock;
  final double unitCost;
  final double salePrice;
  final String? model;
  final int point;
  final String unit;
  final bool isActive;
  final int? updatedByUserId;
  final String? updatedByUserName;
  final DateTime? updatedAt;

  bool get hasLowStock => stock <= minStock;

  Product copyWith({
    String? name,
    String? model,
    int? stock,
    int? minStock,
    int? point,
    String? unit,
    bool? isActive,
    double? unitCost,
    double? salePrice,
    int? updatedByUserId,
    String? updatedByUserName,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id,
        sku: sku,
        name: name ?? this.name,
        stock: stock ?? this.stock,
        minStock: minStock ?? this.minStock,
        unitCost: unitCost ?? this.unitCost,
        salePrice: salePrice ?? this.salePrice,
        model: model ?? this.model,
        point: point ?? this.point,
        unit: unit ?? this.unit,
        isActive: isActive ?? this.isActive,
        updatedByUserId: updatedByUserId ?? this.updatedByUserId,
        updatedByUserName: updatedByUserName ?? this.updatedByUserName,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
