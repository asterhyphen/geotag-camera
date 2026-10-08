import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/pastel_theme.dart';
import '../../../../core/widgets/cute_badge.dart';
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
            child: CuteBadge(
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
                  ? PastelColors.peachDeep
                  : PastelColors.mint,
              onTap: onOpenLocationPicker,
            ),
          ),

          const SizedBox(width: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exposure EV Badge (Quick toggle)
              CuteBadge(
                icon: Icons.wb_sunny_rounded,
                label:
                    '${exposureOffset >= 0 ? '+' : ''}${exposureOffset.toStringAsFixed(1)} EV',
                color: showExposureSlider
                    ? PastelColors.butter
                    : PastelColors.lavender,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleExposureSlider();
                },
              ),
              const SizedBox(width: 6),
              // Selfie / Rear Badge
              CuteBadge(
                icon: isFrontCamera
                    ? Icons.face_retouching_natural_rounded
                    : Icons.camera_rear_rounded,
                label: isFrontCamera ? 'Selfie' : 'Rear',
                color: PastelColors.lavender,
              ),
              const SizedBox(width: 6),
              // Ratio Badge
              CuteBadge(
                icon: Icons.aspect_ratio_rounded,
                label: getAspectRatioLabel(aspectRatio),
                color: PastelColors.sky,
                onTap: onShowAspectRatioSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
