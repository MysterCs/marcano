import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../data/models/descriptive_statistics.dart';

class MonthlyRotationChart extends StatelessWidget {
  const MonthlyRotationChart({
    required this.points,
    super.key,
  });

  final List<MonthlyRotationPoint> points;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('es_ES');
    final totalEntries = points.fold<double>(0, (s, p) => s + p.entries);
    final totalExits = points.fold<double>(0, (s, p) => s + p.exits);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.stacked_bar_chart_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rotación Mensual (Entradas vs. Salidas)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Histórico de movimientos registrados e importados',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white60,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(
                      color: const Color(0xFF3B82F6),
                      label: 'Entradas (${fmt.format(totalEntries.round())})',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: const Color(0xFFF97316),
                      label: 'Salidas (${fmt.format(totalExits.round())})',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('No hay movimientos históricos registrados.'),
                ),
              )
            else
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RotationBarPainter(points: points),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _RotationBarPainter extends CustomPainter {
  const _RotationBarPainter({required this.points});

  final List<MonthlyRotationPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const bottomReserve = 26.0;
    final chartHeight = size.height - bottomReserve;
    final maxVal = points
        .map((p) => math.max(p.entries, p.exits))
        .fold<double>(1.0, math.max);

    final gridPaint = Paint()
      ..color = const Color(0xFF2A2A38)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final slotWidth = size.width / points.length;
    final barWidth = math.min(16.0, slotWidth * 0.32);

    final entriesPaint = Paint()..color = const Color(0xFF3B82F6);
    final exitsPaint = Paint()..color = const Color(0xFFF97316);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final centerX = slotWidth * i + slotWidth / 2;

      final entryH = (p.entries / maxVal) * (chartHeight - 8);
      final exitH = (p.exits / maxVal) * (chartHeight - 8);

      final entryRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          chartHeight - entryH,
          barWidth,
          entryH,
        ),
        const Radius.circular(4),
      );
      final exitRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 2,
          chartHeight - exitH,
          barWidth,
          exitH,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(entryRect, entriesPaint);
      canvas.drawRRect(exitRect, exitsPaint);

      final label = p.period.length >= 7 ? p.period.substring(2) : p.period;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RotationBarPainter oldDelegate) =>
      oldDelegate.points != points;
}

