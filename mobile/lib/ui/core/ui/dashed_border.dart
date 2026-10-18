import 'package:flutter/rendering.dart';

import '../themes/dimens.dart';

/// Dashed outline of a rounded rectangle, drawn just inside its box.
/// A [radius] of half the size draws a circle.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  static const _dash = 6.0;
  static const _gap = 4.0;

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = Dimens.borderWidth;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dash + _gap) {
        canvas.drawPath(metric.extractPath(at, at + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
