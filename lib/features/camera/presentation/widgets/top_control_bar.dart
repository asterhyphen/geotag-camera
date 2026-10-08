import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/pastel_theme.dart';
import '../../../../core/widgets/cute_icon_button.dart';

class TopControlBar extends StatelessWidget {
  final bool torchOn;
  final bool showExposureSlider;
  final bool showGrid;
  final bool whiteFrame;
  final bool geocamOn;
  final bool autoRotate;
  final VoidCallback onToggleTorch;
  final VoidCallback onToggleExposureSlider;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleWhiteFrame;
  final VoidCallback onToggleGeocam;
  final VoidCallback onToggleAutoRotate;

  const TopControlBar({
    super.key,
    required this.torchOn,
    required this.showExposureSlider,
    required this.showGrid,
    required this.whiteFrame,
    required this.geocamOn,
    required this.autoRotate,
    required this.onToggleTorch,
    required this.onToggleExposureSlider,
    required this.onToggleGrid,
    required this.onToggleWhiteFrame,
    required this.onToggleGeocam,
    required this.onToggleAutoRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: PastelColors.surfaceDark.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: PastelColors.lavender.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: PastelShadows.soft(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flashlight
            CuteIconButton(
              icon: torchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              isActive: torchOn,
              activeColor: PastelColors.butter,
              tooltip: torchOn ? 'Flashlight On' : 'Flashlight Off',
              onPressed: onToggleTorch,
            ),

            // Exposure Control Toggle
            CuteIconButton(
              icon: showExposureSlider
                  ? Icons.wb_sunny_rounded
                  : Icons.wb_sunny_outlined,
              isActive: showExposureSlider,
              activeColor: PastelColors.butter,
              tooltip: 'Exposure / Brightness',
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleExposureSlider();
              },
            ),

            // Grid Toggle
            CuteIconButton(
              icon: showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
              isActive: showGrid,
              activeColor: PastelColors.sky,
              tooltip: showGrid ? 'Grid On' : 'Grid Off',
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleGrid();
              },
            ),

            // White Frame
            CuteIconButton(
              icon: whiteFrame
                  ? Icons.crop_square_rounded
                  : Icons.filter_frames_outlined,
              isActive: whiteFrame,
              activeColor: PastelColors.pink,
              tooltip: whiteFrame ? 'White Frame On' : 'White Frame Off',
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleWhiteFrame();
              },
            ),

            // Geotag Watermark
            CuteIconButton(
              icon: geocamOn
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
              isActive: geocamOn,
              activeColor: PastelColors.mint,
              tooltip: geocamOn ? 'Geotag On' : 'Geotag Off',
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleGeocam();
              },
            ),

            // Auto Rotate
            CuteIconButton(
              icon: autoRotate
                  ? Icons.screen_rotation_rounded
                  : Icons.screen_lock_rotation_rounded,
              isActive: autoRotate,
              activeColor: PastelColors.peach,
              tooltip: autoRotate ? 'Auto Rotate On' : 'Locked Upright',
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleAutoRotate();
              },
            ),
          ],
        ),
      ),
    );
  }
}
