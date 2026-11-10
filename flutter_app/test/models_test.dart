import 'package:flutter_test/flutter_test.dart';
import 'package:marcano_flutter/data/models/product.dart';
import 'package:marcano_flutter/data/models/projection_point.dart';

void main() {
  test('Product interpreta el JSON de la API', () {
    final product = Product.fromJson({
      'id': 1,
      'sku': 'A-001',
      'name': 'Articulo',
      'stock': 4,
      'min_stock': 5,
      'unit_cost': 10.5,
      'sale_price': 15,
    });

    expect(product.hasLowStock, isTrue);
    expect(product.salePrice, 15.0);
  });

  test('ProjectionPoint interpreta la fecha y la cantidad', () {
    final point = ProjectionPoint.fromJson({
      'period': '2027-01-01',
      'quantity': 12.5,
      'movement': 'sale',
    });

    expect(point.period.year, 2027);
    expect(point.quantity, 12.5);
  });
}
