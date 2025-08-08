import 'dart:math';
import 'package:flutter/material.dart';

class DottedCirclePainter extends CustomPainter {
  final double progress;
  final int totalDots;
  final double dotRadius;
  final Color? activeProgressColor;
  final Color? progressColor;

  DottedCirclePainter({
    required this.progress,
    this.totalDots = 60,
    this.dotRadius = 3.0,
    this.activeProgressColor,
    this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double spacingOffset = dotRadius * 2; // Extra spacing for green dots
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) + spacingOffset;

    final Paint dotPaint = Paint()..style = PaintingStyle.fill;

    int greenDotsCount = (progress * totalDots).round();

    double normalSpacing = (2 * pi) / totalDots; // Regular spacing

    double currentAngle = -pi / 2; // Start from the top

    for (int i = 0; i < totalDots; i++) {
      double x = center.dx + radius * cos(currentAngle);
      double y = center.dy + radius * sin(currentAngle);

      if (i < greenDotsCount) {
        dotPaint.color = activeProgressColor ?? Colors.green;
        canvas.drawCircle(Offset(x, y), dotRadius + 1.5, dotPaint);
      } else {
        dotPaint.color = progressColor ?? Colors.red;
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }

      currentAngle += normalSpacing; // Keep spacing consistent
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
