import 'package:flutter/material.dart';
import '../theme/pastel_theme.dart';

/// A cute frosted pastel icon button with bouncy feedback and active glow
class CuteIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color? activeBgColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Widget? badge;

  const CuteIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.activeColor = PastelColors.pinkDeep,
    this.inactiveColor = PastelColors.textLight,
    this.activeBgColor,
    this.size = 46,
    this.iconSize = 22,
    this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveBg =
        activeBgColor ?? activeColor.withValues(alpha: 0.22);

    Widget button = BouncyTap(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive
                  ? effectiveActiveBg
                  : PastelColors.cardDark.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.6)
                    : PastelColors.lavender.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          if (badge != null) Positioned(top: -2, right: -2, child: badge!),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
