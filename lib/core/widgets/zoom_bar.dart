import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Camera zoom control bar with step adjustments and quick presets
class ZoomBar extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onStartContinuousIn;
  final VoidCallback onStartContinuousOut;
  final VoidCallback onStopContinuous;

  const ZoomBar({
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
        color: AppColors.cardDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.18),
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
                color: AppColors.surfaceDark.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_rounded,
                size: 15,
                color: AppColors.lavender,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Zoom presets (1x, 2x, 3x)
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
                color: AppColors.surfaceDark.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 15,
                color: AppColors.pink,
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
              ? AppColors.pink.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${targetZoom.toStringAsFixed(targetZoom.truncateToDouble() == targetZoom ? 0 : 1)}x',
          style: TextStyle(
            color: isSelected ? AppColors.textDark : AppColors.textLight,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
