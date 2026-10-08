import 'package:flutter/material.dart';
import '../../../../core/theme/pastel_theme.dart';

class VintageFilmFrameOverlay extends StatelessWidget {
  final String filterName;
  final bool geocamOn;

  const VintageFilmFrameOverlay({
    super.key,
    required this.filterName,
    this.geocamOn = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Corner ticks & rangefinder reticle
          CustomPaint(
            painter: VintageFramePainter(),
          ),
          // Top Vintage Markings Bar
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: PastelColors.butter.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 10,
                            color: PastelColors.butter,
                          ),
                          Text(
                            '24A',
                            style: TextStyle(
                              color: PastelColors.butter,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '35mm FILM',
                      style: TextStyle(
                        color: PastelColors.textLight.withValues(alpha: 0.65),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: PastelColors.lavender.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'ISO 400 • ${filterName.toUpperCase()}',
                    style: TextStyle(
                      color: PastelColors.peach.withValues(alpha: 0.95),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Vintage Markings (hidden when watermark zone is active)
          if (!geocamOn)
            Positioned(
              bottom: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'GEOCAM 1:1.8/35mm',
                  style: TextStyle(
                    color: PastelColors.lavender,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VintageFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.butter.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;
    const cornerLen = 14.0;
    const inset = 14.0;

    // Top-left
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + cornerLen, inset),
      paint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset, inset + cornerLen),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(w - inset, inset),
      Offset(w - inset - cornerLen, inset),
      paint,
    );
    canvas.drawLine(
      Offset(w - inset, inset),
      Offset(w - inset, inset + cornerLen),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(inset, h - inset),
      Offset(inset + cornerLen, h - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, h - inset),
      Offset(inset, h - inset - cornerLen),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(w - inset, h - inset),
      Offset(w - inset - cornerLen, h - inset),
      paint,
    );
    canvas.drawLine(
      Offset(w - inset, h - inset),
      Offset(w - inset, h - inset - cornerLen),
      paint,
    );

    // Center crosshair
    final centerPaint = Paint()
      ..color = PastelColors.lavender.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = w / 2;
    final cy = h / 2;
    const crossLen = 6.0;
    canvas.drawLine(
      Offset(cx - crossLen, cy),
      Offset(cx + crossLen, cy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - crossLen),
      Offset(cx, cy + crossLen),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
