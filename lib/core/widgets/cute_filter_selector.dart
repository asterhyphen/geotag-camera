import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pastel_theme.dart';

/// Filter Option model
class FilterOption {
  final String id;
  final String name;
  final Color accentColor;
  final IconData icon;

  const FilterOption({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.icon,
  });
}

const List<FilterOption> kFilterOptions = [
  FilterOption(
    id: 'none',
    name: 'Natural',
    accentColor: PastelColors.pink,
    icon: Icons.auto_awesome_rounded,
  ),
  FilterOption(
    id: 'vintage',
    name: 'Vintage',
    accentColor: PastelColors.peach,
    icon: Icons.filter_vintage_rounded,
  ),
  FilterOption(
    id: 'mono',
    name: 'Mono',
    accentColor: PastelColors.lavender,
    icon: Icons.contrast_rounded,
  ),
  FilterOption(
    id: 'sepia',
    name: 'Sepia',
    accentColor: PastelColors.butter,
    icon: Icons.wb_sunny_rounded,
  ),
];

/// Cute horizontal filter carousel
class CuteFilterSelector extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterSelected;

  const CuteFilterSelector({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: PastelColors.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PastelColors.lavender.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: kFilterOptions.map((opt) {
          final isSelected = currentFilter == opt.id;

          return Expanded(
            child: BouncyTap(
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterSelected(opt.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            opt.accentColor,
                            opt.accentColor.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: opt.accentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected
                          ? PastelColors.textDark
                          : PastelColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      opt.name,
                      style: TextStyle(
                        color: isSelected
                            ? PastelColors.textDark
                            : PastelColors.textMuted,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
