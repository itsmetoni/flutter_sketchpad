import 'package:flutter/material.dart';

import 'sketch_insert.dart';
import 'sketch_mode.dart';

/// Custom painter for rendering sketch inserts
class SketchInsertPainter extends CustomPainter {
  SketchInsertPainter({
    required this.inserts,
    required this.currentPoints,
    required this.currentStrokeWidth,
    required this.currentColor,
    required this.currentMode,
  });

  final List<SketchInsert> inserts;
  final List<Offset> currentPoints;
  final double currentStrokeWidth;
  final Color currentColor;
  final SketchMode currentMode;

  @override
  void paint(Canvas canvas, Size size) {
    // Save layer for proper blending
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw all saved inserts in chronological order (creation order)
    // This ensures proper layering where newer content can appear over erased areas
    for (final insert in inserts) {
      if (insert.type == SketchInsertType.eraser) {
        // Use blend mode clear for eraser types
        _drawEraserPath(canvas, insert.points, insert.strokeWidth);
      } else {
        // Use normal drawing for other types
        // Non-eraser inserts should always have a color, but fallback to black just in case
        _drawPath(canvas, insert.points, insert.color ?? Colors.black,
            insert.strokeWidth);
      }
    }

    // Draw current stroke being drawn
    if (currentPoints.isNotEmpty) {
      if (currentMode == SketchMode.eraser) {
        _drawEraserPath(canvas, currentPoints, currentStrokeWidth);
      } else {
        _drawPath(canvas, currentPoints, currentColor, currentStrokeWidth);
      }
    }

    // Restore the layer
    canvas.restore();
  }

  void _drawPath(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawEraserPath(
    Canvas canvas,
    List<Offset> points,
    double strokeWidth,
  ) {
    if (points.length < 2) return;

    final paint = Paint()
      ..blendMode = BlendMode.clear // Clear pixels to transparent
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SketchInsertPainter oldDelegate) {
    return oldDelegate.inserts != inserts ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentMode != currentMode;
  }
}
