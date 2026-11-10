class DollarRate {
  const DollarRate({this.value, this.source, this.updatedAt});

  factory DollarRate.fromJson(Map<String, dynamic> json) => DollarRate(
        value: (json['value'] as num?)?.toDouble(),
        source: json['source'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.tryParse(json['updated_at'] as String),
      );

  final double? value;
  final String? source;
  final DateTime? updatedAt;

  bool get hasValue => value != null && value! > 0;
}
