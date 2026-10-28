import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../location/domain/models/location_stamp.dart';
import '../../domain/models/aspect_ratio_option.dart';

class StatusRibbon extends StatelessWidget {
  final LocationStamp? customLocation;
  final LocationStamp? cachedLocationStamp;
  final double exposureOffset;
  final bool showExposureSlider;
  final bool isFrontCamera;
  final double aspectRatio;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onToggleExposureSlider;
  final VoidCallback onShowAspectRatioSheet;

  const StatusRibbon({
    super.key,
    required this.customLocation,
    required this.cachedLocationStamp,
    required this.exposureOffset,
    required this.showExposureSlider,
    required this.isFrontCamera,
    required this.aspectRatio,
    required this.onOpenLocationPicker,
    required this.onToggleExposureSlider,
    required this.onShowAspectRatioSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location Status Pill (Tap to edit custom location)
          Flexible(
            child: StatusBadge(
              icon: customLocation != null
                  ? Icons.edit_location_alt_rounded
                  : (cachedLocationStamp != null
                      ? Icons.location_on_rounded
                      : Icons.gps_fixed_rounded),
              label: customLocation != null
                  ? customLocation!.location
                  : (cachedLocationStamp != null &&
                          cachedLocationStamp!.location.isNotEmpty
                      ? cachedLocationStamp!.location
                      : 'GPS Auto'),
              color: customLocation != null
                  ? AppColors.peachDeep
                  : AppColors.mint,
              onTap: onOpenLocationPicker,
            ),
          ),

          const SizedBox(width: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exposure EV Badge (Quick toggle)
              StatusBadge(
                icon: Icons.wb_sunny_rounded,
                label:
                    '${exposureOffset >= 0 ? '+' : ''}${exposureOffset.toStringAsFixed(1)} EV',
                color: showExposureSlider
                    ? AppColors.butter
                    : AppColors.lavender,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleExposureSlider();
                },
              ),
              const SizedBox(width: 6),
              // Selfie / Rear Badge
              StatusBadge(
                icon: isFrontCamera
                    ? Icons.face_retouching_natural_rounded
                    : Icons.camera_rear_rounded,
                label: isFrontCamera ? 'Selfie' : 'Rear',
                color: AppColors.lavender,
              ),
              const SizedBox(width: 6),
              // Ratio Badge
              StatusBadge(
                icon: Icons.aspect_ratio_rounded,
                label: getAspectRatioLabel(aspectRatio),
                color: AppColors.sky,
                onTap: onShowAspectRatioSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
