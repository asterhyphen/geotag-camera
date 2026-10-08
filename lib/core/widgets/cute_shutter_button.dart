import 'package:flutter/material.dart';
import '../theme/pastel_theme.dart';

/// A showstopping cute shutter button with pulsing aura, candy colors, and spring feel
class CuteShutterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool processing;
  final double size;

  const CuteShutterButton({
    super.key,
    required this.onTap,
    required this.processing,
    this.size = 80,
  });

  @override
  State<CuteShutterButton> createState() => _CuteShutterButtonState();
}

class _CuteShutterButtonState extends State<CuteShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: widget.processing ? null : widget.onTap,
      scaleDown: 0.88,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final glowScale = 1.0 + (_pulseCtrl.value * 0.08);

          return SizedBox(
            width: widget.size + 16,
            height: widget.size + 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer aura
                Transform.scale(
                  scale: glowScale,
                  child: Container(
                    width: widget.size + 8,
                    height: widget.size + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          PastelColors.pink.withValues(alpha: 0.35),
                          PastelColors.lavender.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // Frosted pastel outer ring
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        PastelColors.pink,
                        PastelColors.lavender,
                        PastelColors.sky,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PastelColors.pink.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: PastelColors.surfaceDark,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.processing
                              ? [PastelColors.lavender, PastelColors.sky]
                              : [
                                  PastelColors.pink,
                                  PastelColors.peach,
                                  PastelColors.butter,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: widget.processing
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
