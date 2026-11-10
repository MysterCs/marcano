import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/descriptive_statistics.dart';

class StockHealthDonutChart extends StatelessWidget {
  const StockHealthDonutChart({
    required this.health,
    super.key,
  });

  final StockHealthSummary health;

  @override
  Widget build(BuildContext context) {
    final total = health.optimalCount +
        health.lowStockCount +
        health.outOfStockCount +
        health.inactiveCount;
    final fmt = NumberFormat.decimalPattern('es_ES');

    final segments = [
      _Segment(
        label: 'Stock óptimo',
        count: health.optimalCount,
        color: const Color(0xFF10B981),
        icon: Icons.check_circle_outline,
      ),
      _Segment(
        label: 'Stock bajo',
        count: health.lowStockCount,
        color: const Color(0xFFF97316),
        icon: Icons.warning_amber_rounded,
      ),
      _Segment(
        label: 'Agotados (0)',
        count: health.outOfStockCount,
        color: const Color(0xFFE11D48),
        icon: Icons.error_outline,
      ),
      _Segment(
        label: 'Inactivos',
        count: health.inactiveCount,
        color: const Color(0xFF6B7280),
        icon: Icons.pause_circle_outline,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.donut_large_outlined,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salud del Inventario',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Distribución por estado de existencias',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 420;
                final chart = SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(170, 170),
                        painter: _DonutPainter(segments: segments, total: total),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmt.format(total),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'SKUs',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final legend = Column(
                  children: segments.map((seg) {
                    final pct = total > 0 ? (seg.count / total * 100) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: seg.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(seg.icon, size: 16, color: seg.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              seg.label,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${fmt.format(seg.count)} (${pct.toStringAsFixed(1)}%)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );

                if (wide) {
                  return Row(
                    children: [
                      chart,
                      const SizedBox(width: 28),
                      Expanded(child: legend),
                    ],
                  );
                }
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: 20),
                    legend,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.total,
  });

  final List<_Segment> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = const Color(0xFF2A2A38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      if (seg.count <= 0) continue;
      final sweep = (seg.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.segments != segments;
}

