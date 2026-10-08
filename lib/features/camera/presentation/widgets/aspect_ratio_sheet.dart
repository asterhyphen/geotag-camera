import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/pastel_theme.dart';
import '../../domain/models/aspect_ratio_option.dart';

void showAspectRatioSheet({
  required BuildContext context,
  required double currentRatio,
  required ValueChanged<double> onRatioSelected,
}) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PastelColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: PastelColors.lavender.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PastelColors.lavender.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aspect Ratio',
              style: TextStyle(
                color: PastelColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: kAspectRatioOptions.map((item) {
                final double r = item.ratio;
                final isSelected = (currentRatio - r).abs() < 0.05;

                return BouncyTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRatioSelected(r);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PastelColors.pink.withValues(alpha: 0.25)
                          : PastelColors.cardDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? PastelColors.pink
                            : PastelColors.lavender.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? PastelColors.pink
                              : PastelColors.textMuted,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? PastelColors.pink
                                : PastelColors.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          item.sub,
                          style: const TextStyle(
                            color: PastelColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
