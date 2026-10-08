import 'package:flutter/material.dart';
import '../../../../core/theme/pastel_theme.dart';

class CuteGridOverlay extends StatelessWidget {
  const CuteGridOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: CuteGridPainter(),
      ),
    );
  }
}

class CuteGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.lavender.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = PastelColors.pink.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Rule of thirds lines
    final x1 = w / 3;
    final x2 = (w / 3) * 2;
    final y1 = h / 3;
    final y2 = (h / 3) * 2;

    // Vertical lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, h), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, h), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, y1), Offset(w, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(w, y2), paint);

    // Cute dots at intersection points
    const dotRadius = 2.5;
    canvas.drawCircle(Offset(x1, y1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x2, y1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x1, y2), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x2, y2), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
