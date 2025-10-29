// lib/angle_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

class AnglePainter extends CustomPainter {
  final double angleInDegrees; // This can now be negative or positive
  final bool hasReference;
  final bool isAngleTooLarge; // Flag for the warning state
  final bool isDarkMode;

  AnglePainter({
    required this.angleInDegrees,
    required this.hasReference,
    required this.isAngleTooLarge,
    this.isDarkMode = true, // Default to dark mode for backward compatibility
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // --- Dynamic Paint for the circle slice ---
    // Change color based on the angle
    final fillPaint = Paint()
      ..color = isAngleTooLarge
          ? Colors.red.withAlpha(120) // Warning color
          : Colors.teal.withAlpha(100) // Normal color
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = isDarkMode ? Colors.white : Colors.grey[800]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // --- 1. Draw the static line pointing to "B" (always forward) ---
    canvas.drawLine(center, Offset(center.dx, center.dy - radius), linePaint);

    if (hasReference) {
      // The angle is now signed, so it will correctly draw left or right
      final angleInRadians = angleInDegrees * (pi / 180);

      // --- 2. Draw the dynamic line pointing to "C" ---
      final referencePoint = Offset(
        center.dx + radius * cos(angleInRadians - (pi / 2)),
        center.dy + radius * sin(angleInRadians - (pi / 2)),
      );
      canvas.drawLine(center, referencePoint, linePaint);

      // --- 3. Draw the arc (the circle slice) ---
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start angle (pointing up)
        angleInRadians, // The sweep angle is now correctly signed
        true,
        fillPaint,
      );

      // --- 4. Draw the warning message if the angle is too large ---
      if (isAngleTooLarge) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'Angle > 90°\nResults may be inaccurate',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.grey[900],
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: isDarkMode ? Colors.black : Colors.grey[400]!,
                )
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout(minWidth: 0, maxWidth: size.width);
        // Position the text in the center of the painter
        textPainter.paint(canvas, Offset(0, center.dy - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnglePainter oldDelegate) {
    return oldDelegate.angleInDegrees != angleInDegrees ||
        oldDelegate.hasReference != hasReference ||
        oldDelegate.isAngleTooLarge != isAngleTooLarge ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}