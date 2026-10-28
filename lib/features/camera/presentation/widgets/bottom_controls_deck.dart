import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/shutter_button.dart';

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
          AppIconButton(
            icon: Icons.aspect_ratio_rounded,
            size: 52,
            iconSize: 24,
            activeColor: AppColors.sky,
            tooltip: 'Change Aspect Ratio',
            onPressed: onShowAspectRatioSheet,
          ),

          // Shutter Button
          ShutterButton(
            onTap: onCapture,
            processing: isProcessing,
            size: 82,
          ),

          // Flip Camera Button
          AppIconButton(
            icon: Icons.flip_camera_ios_rounded,
            size: 52,
            iconSize: 24,
            activeColor: AppColors.lavender,
            tooltip: 'Flip Camera',
            onPressed: onSwitchCamera,
          ),
        ],
      ),
    );
  }
}
