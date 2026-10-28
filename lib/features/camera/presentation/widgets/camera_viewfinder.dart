import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/focus_ring.dart';
import '../../../location/domain/models/location_stamp.dart';
import '../../../watermark/data/services/date_time_formatter.dart';
import '../../../watermark/presentation/widgets/watermark_area_guide.dart';
import 'camera_preview_widget.dart';
import 'film_frame_overlay.dart';
import 'grid_overlay.dart';

class CameraViewfinder extends StatelessWidget {
  final CameraController controller;
  final double aspectRatio;
  final String filter;
  final bool showGrid;
  final bool geocamOn;
  final LocationStamp effectiveLocation;
  final Offset? focusPoint;
  final double exposureOffset;
  final Animation<double> flashAnim;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onSwitchCamera;
  final void Function(TapUpDetails details, Size viewSize) onTapToFocus;
  final void Function(double newZoom) onZoomUpdated;

  const CameraViewfinder({
    super.key,
    required this.controller,
    required this.aspectRatio,
    required this.filter,
    required this.showGrid,
    required this.geocamOn,
    required this.effectiveLocation,
    required this.focusPoint,
    required this.exposureOffset,
    required this.flashAnim,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onSwitchCamera,
    required this.onTapToFocus,
    required this.onZoomUpdated,
  });

  @override
  Widget build(BuildContext context) {
    double pinchStartZoom = zoom;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.lavender.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return GestureDetector(
                    onDoubleTap: onSwitchCamera,
                    onTapUp: (details) => onTapToFocus(details, viewSize),
                    onScaleStart: (_) {
                      pinchStartZoom = zoom;
                    },
                    onScaleUpdate: (details) {
                      final adjustedScale = 1 + ((details.scale - 1) * 0.3);
                      final newZoom = (pinchStartZoom * adjustedScale).clamp(
                        minZoom,
                        maxZoom,
                      );
                      controller.setZoomLevel(newZoom);
                      onZoomUpdated(newZoom);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreviewWidget(controller: controller),
                        if (showGrid) const GridOverlay(),

                        // Frame Overlay
                        FilmFrameOverlay(
                          filterName: filter,
                          geocamOn: geocamOn,
                        ),

                        // Watermark Area Preview Rectangle
                        WatermarkAreaGuide(
                          visible: geocamOn,
                          location: effectiveLocation.location,
                          address: effectiveLocation.address,
                          latLng: effectiveLocation.latLng,
                          dateTime: formatDateTime(),
                          previewHeight: viewSize.height,
                          previewWidth: viewSize.width,
                        ),

                        // Focus Reticle Ring
                        if (focusPoint != null)
                          FocusRing(
                            position: focusPoint!,
                            exposureOffset: exposureOffset,
                          ),

                        // Capture Flash Effect
                        AnimatedBuilder(
                          animation: flashAnim,
                          builder: (context, child) {
                            if (flashAnim.value == 0) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              color: AppColors.pinkLight.withValues(
                                alpha: flashAnim.value * 0.85,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
