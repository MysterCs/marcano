class ProjectionPoint {
  const ProjectionPoint({
    required this.period,
    required this.quantity,
    required this.movement,
  });

  factory ProjectionPoint.fromJson(Map<String, dynamic> json) =>
      ProjectionPoint(
        period: DateTime.parse(json['period'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        movement: json['movement'] as String,
      );

  final DateTime period;
  final double quantity;
  final String movement;
}
