import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pastel_theme.dart';

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
              color: isActive ? effectiveActiveBg : PastelColors.cardDark.withValues(alpha: 0.65),
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
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: badge!,
            ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A delightful mini pill badge for status updates
class CuteBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  final VoidCallback? onTap;

  const CuteBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = PastelColors.lavender,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return BouncyTap(
        onTap: onTap,
        child: badgeWidget,
      );
    }
    return badgeWidget;
  }
}

enum VintageAlertVariant { info, success, warning, error }

/// A vintage pastel floating alert toast for bottom notifications and errors
void showVintageAlert(
  BuildContext context, {
  required String message,
  VintageAlertVariant variant = VintageAlertVariant.info,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  Color accentColor;
  IconData defaultIcon;

  switch (variant) {
    case VintageAlertVariant.success:
      accentColor = PastelColors.mint;
      defaultIcon = Icons.check_circle_rounded;
      break;
    case VintageAlertVariant.warning:
      accentColor = PastelColors.butter;
      defaultIcon = Icons.warning_amber_rounded;
      break;
    case VintageAlertVariant.error:
      accentColor = PastelColors.pinkDeep;
      defaultIcon = Icons.error_outline_rounded;
      break;
    case VintageAlertVariant.info:
      accentColor = PastelColors.lavender;
      defaultIcon = Icons.info_outline_rounded;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PastelColors.surfaceDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? defaultIcon,
                size: 16,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: PastelColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
                                      color: Colors.white.withValues(alpha: 0.6),
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
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
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
            onTap: () => onZoomChanged((currentZoom - 0.1).clamp(minZoom, maxZoom)),
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
            onTap: () => onZoomChanged((currentZoom + 0.1).clamp(minZoom, maxZoom)),
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
        boxShadow: PastelShadows.soft(color: PastelColors.butter.withValues(alpha: 0.15)),
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
                inactiveTrackColor: PastelColors.lavender.withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - tickLen, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, tickLen), cornerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

