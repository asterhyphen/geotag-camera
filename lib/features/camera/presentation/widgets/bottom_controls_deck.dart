import 'package:flutter/material.dart';
import '../../../../core/theme/pastel_theme.dart';
import '../../../../core/widgets/cute_icon_button.dart';
import '../../../../core/widgets/cute_shutter_button.dart';

class BottomControlsDeck extends StatelessWidget {
  final VoidCallback onShowAspectRatioSheet;
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final bool isProcessing;

  const BottomControlsDeck({
    super.key,
    required this.onShowAspectRatioSheet,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ratio / Aspect Button
          CuteIconButton(
            icon: Icons.aspect_ratio_rounded,
            size: 52,
            iconSize: 24,
            activeColor: PastelColors.sky,
            tooltip: 'Change Aspect Ratio',
            onPressed: onShowAspectRatioSheet,
          ),

          // Big Cute Shutter Button
          CuteShutterButton(
            onTap: onCapture,
            processing: isProcessing,
            size: 82,
          ),

          // Flip Camera Button
          CuteIconButton(
            icon: Icons.flip_camera_ios_rounded,
            size: 52,
            iconSize: 24,
            activeColor: PastelColors.lavender,
            tooltip: 'Flip Camera',
            onPressed: onSwitchCamera,
          ),
        ],
      ),
    );
  }
}
