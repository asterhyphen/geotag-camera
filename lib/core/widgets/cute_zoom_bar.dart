import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pastel_theme.dart';

/// Quick Zoom bar with preset pills and smooth step buttons
class CuteZoomBar extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onStartContinuousIn;
  final VoidCallback onStartContinuousOut;
  final VoidCallback onStopContinuous;

  const CuteZoomBar({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    required this.onStartContinuousIn,
    required this.onStartContinuousOut,
    required this.onStopContinuous,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PastelColors.cardDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PastelColors.lavender.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out (-)
          BouncyTap(
            onTap: () =>
                onZoomChanged((currentZoom - 0.1).clamp(minZoom, maxZoom)),
            onLongPress: onStartContinuousOut,
            onLongPressUp: onStopContinuous,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: PastelColors.surfaceDark.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_rounded,
                size: 15,
                color: PastelColors.lavender,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Zoom pills (e.g. 1.0x, 2.0x, 3.0x if supported)
          _buildZoomChip(1.0),
          if (maxZoom >= 2.0) ...[
            const SizedBox(width: 6),
            _buildZoomChip(2.0),
          ],
          if (maxZoom >= 3.0) ...[
            const SizedBox(width: 6),
            _buildZoomChip(3.0),
          ],

          const SizedBox(width: 8),

          // Zoom in (+)
          BouncyTap(
            onTap: () =>
                onZoomChanged((currentZoom + 0.1).clamp(minZoom, maxZoom)),
            onLongPress: onStartContinuousIn,
            onLongPressUp: onStopContinuous,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: PastelColors.surfaceDark.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 15,
                color: PastelColors.pink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomChip(double targetZoom) {
    final isSelected = (currentZoom - targetZoom).abs() < 0.15;
    return BouncyTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onZoomChanged(targetZoom.clamp(minZoom, maxZoom));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? PastelColors.pink.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${targetZoom.toStringAsFixed(targetZoom.truncateToDouble() == targetZoom ? 0 : 1)}x',
          style: TextStyle(
            color: isSelected ? PastelColors.textDark : PastelColors.textLight,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
