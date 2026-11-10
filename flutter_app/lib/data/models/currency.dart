class BcvCurrency {
  const BcvCurrency({required this.name, required this.value});

  factory BcvCurrency.fromJson(Map<String, dynamic> json) => BcvCurrency(
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
      );

  final String name;
  final double value;

  Map<String, dynamic> toJson({String source = 'bcv'}) => {
        'name': name,
        'value': value,
        'source': source,
      };
}

class AlternateCurrency {
  const AlternateCurrency({
    required this.id,
    required this.name,
    required this.value,
    required this.source,
    this.updatedAt,
  });

  factory AlternateCurrency.fromJson(Map<String, dynamic> json) =>
      AlternateCurrency(
        id: json['id'] as int,
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        source: (json['source'] as String?) ?? 'bcv',
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.tryParse(json['updated_at'] as String),
      );

  final int id;
  final String name;
  final double value;
  final String source;
  final DateTime? updatedAt;
}
