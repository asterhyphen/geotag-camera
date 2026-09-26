import 'package:flutter/material.dart';

class PastelColors {
  // Soft Pastel Palettes
  static const Color pink = Color(0xFFFFB5C5);
  static const Color pinkLight = Color(0xFFFFF0F3);
  static const Color pinkDeep = Color(0xFFF06292);

  static const Color lavender = Color(0xFFD6C7FF);
  static const Color lavenderLight = Color(0xFFF3EFFF);
  static const Color lavenderDeep = Color(0xFF8B72DE);

  static const Color mint = Color(0xFFB5EAD7);
  static const Color mintLight = Color(0xFFE8F8F2);
  static const Color mintDeep = Color(0xFF4CAF90);

  static const Color peach = Color(0xFFFFDAC1);
  static const Color peachLight = Color(0xFFFFF6EE);
  static const Color peachDeep = Color(0xFFFF8A65);

  static const Color butter = Color(0xFFFFF1AA);
  static const Color butterLight = Color(0xFFFFFBE6);

  static const Color sky = Color(0xFFBAE1FF);
  static const Color skyLight = Color(0xFFEFF7FF);

  // Background & Surface tones
  static const Color bgDark = Color(0xFF16131D);
  static const Color surfaceDark = Color(0xFF211C2B);
  static const Color cardDark = Color(0xFF2C2538);
  static const Color borderDark = Color(0x33D6C7FF);

  // Text & Icon tones
  static const Color textLight = Color(0xFFFAF7FC);
  static const Color textMuted = Color(0xFFB3A8C5);
  static const Color textDark = Color(0xFF322A40);

  // Gradients
  static const LinearGradient magicGradient = LinearGradient(
    colors: [pink, lavender, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [pink, peach, butter],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintyGradient = LinearGradient(
    colors: [mint, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shutterGradient = LinearGradient(
    colors: [Color(0xFFFFB5C5), Color(0xFFE4A4FF), Color(0xFFBAE1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class PastelShadows {
  static List<BoxShadow> soft({Color color = const Color(0x2A000000)}) => [
    BoxShadow(
      color: color,
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.45),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];
}

/// A playful, tactile bouncing widget on tap
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressUp;
  final double scaleDown;
  final Duration duration;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onLongPressUp,
    this.scaleDown = 0.90,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: () {
        _controller.forward();
        widget.onLongPress?.call();
      },
      onLongPressUp: () {
        _controller.reverse();
        widget.onLongPressUp?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
