import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pastel_theme.dart';

/// Vintage Exposure Compensation Slider
class VintageExposureSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onClose;

  const VintageExposureSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final evString = '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} EV';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: PastelColors.surfaceDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PastelColors.butter.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: PastelShadows.soft(
          color: PastelColors.butter.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_sunny_rounded,
            size: 16,
            color: PastelColors.butter,
          ),
          const SizedBox(width: 8),
          Text(
            evString,
            style: const TextStyle(
              color: PastelColors.butter,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: PastelColors.butter,
                inactiveTrackColor: PastelColors.lavender.withValues(
                  alpha: 0.25,
                ),
                thumbColor: PastelColors.butter,
                overlayColor: PastelColors.butter.withValues(alpha: 0.2),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: (newVal) {
                  HapticFeedback.selectionClick();
                  onChanged(newVal);
                },
              ),
            ),
          ),
          if (onClose != null)
            BouncyTap(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PastelColors.cardDark.withValues(alpha: 0.6),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: PastelColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
