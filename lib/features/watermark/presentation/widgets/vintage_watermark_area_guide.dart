import 'package:flutter/material.dart';
import '../../../../core/theme/pastel_theme.dart';

/// A vintage dashed/gradient preview rectangle indicating the exact area covered by the watermark in the final photo
class VintageWatermarkAreaGuide extends StatelessWidget {
  final bool visible;
  final String location;
  final String address;
  final String latLng;
  final String dateTime;
  final double previewHeight;
  final double previewWidth;

  const VintageWatermarkAreaGuide({
    super.key,
    required this.visible,
    this.location = '',
    this.address = '',
    this.latLng = '',
    this.dateTime = '',
    required this.previewHeight,
    required this.previewWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final overlayH = previewHeight * 0.20;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: overlayH,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x9916131D),
                  Color(0xE616131D),
                ],
                stops: [0.0, 0.25, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dashed guide boundary line & corner markers along the top of the watermark zone
                CustomPaint(
                  painter: _WatermarkBorderPainter(),
                ),

                // Top indicator tag badge
                Positioned(
                  top: 4,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: PastelColors.peach.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 9,
                          color: PastelColors.peach,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'WATERMARK ZONE (20%)',
                          style: TextStyle(
                            color: PastelColors.peach,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Live typography overlay preview
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: previewWidth * 0.08,
                    vertical: overlayH * 0.10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (location.isNotEmpty)
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFAF7FC),
                            fontSize: (overlayH * 0.17).clamp(9.0, 13.0),
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFE8E3EE),
                            fontSize: (overlayH * 0.13).clamp(8.0, 11.0),
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      if (latLng.isNotEmpty)
                        Text(
                          latLng,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PastelColors.lavender,
                            fontSize: (overlayH * 0.11).clamp(7.5, 9.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (dateTime.isNotEmpty)
                        Text(
                          dateTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PastelColors.mint,
                            fontSize: (overlayH * 0.11).clamp(7.5, 9.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (location.isEmpty && address.isEmpty && latLng.isEmpty)
                        Text(
                          '📍 Geotag Watermark Area',
                          style: TextStyle(
                            color: PastelColors.lavender.withValues(alpha: 0.8),
                            fontSize: (overlayH * 0.14).clamp(9.0, 12.0),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                // Accent line at the bottom
                Positioned(
                  bottom: (overlayH * 0.06).clamp(3.0, 8.0),
                  left: previewWidth * 0.08,
                  right: previewWidth * 0.08,
                  child: Container(
                    height: (overlayH * 0.02).clamp(1.5, 3.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB5C5),
                          Color(0xFFD6C7FF),
                          Color(0xFFBAE1FF),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatermarkBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.peach.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed line across top
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Corner tick markers
    final cornerPaint = Paint()
      ..color = PastelColors.peach
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const tickLen = 8.0;
    // Top-left tick
    canvas.drawLine(const Offset(0, 0), const Offset(tickLen, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, tickLen), cornerPaint);

    // Top-right tick
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - tickLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, tickLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
