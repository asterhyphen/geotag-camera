import 'package:flutter/material.dart';
import '../theme/pastel_theme.dart';

/// Animated Vintage Focus Reticle
class VintageFocusRing extends StatelessWidget {
  final Offset position;
  final double exposureOffset;

  const VintageFocusRing({
    super.key,
    required this.position,
    this.exposureOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 34,
      top: position.dy - 34,
      child: IgnorePointer(
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(64, 64),
                painter: _VintageFocusPainter(),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PastelColors.butter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VintageFocusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.butter.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;
    const cornerLen = 10.0;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-right corner
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLen, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLen), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(w, h), Offset(w - cornerLen, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
