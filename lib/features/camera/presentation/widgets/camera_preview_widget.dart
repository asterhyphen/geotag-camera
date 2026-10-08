import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var cameraRatio = controller.value.aspectRatio;
    if (cameraRatio > 1.0) {
      cameraRatio = 1.0 / cameraRatio;
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100,
            height: 100 / (cameraRatio > 0 ? cameraRatio : (3 / 4)),
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
