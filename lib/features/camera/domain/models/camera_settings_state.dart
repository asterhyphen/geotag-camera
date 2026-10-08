import 'dart:ui';

class CameraSettingsState {
  final String filter;
  final double aspectRatio;
  final bool whiteFrame;
  final bool geocamOn;
  final bool autoRotate;
  final bool torchOn;
  final bool torchSupported;
  final bool showGrid;
  final bool showExposureSlider;
  final double exposureOffset;
  final double minExposure;
  final double maxExposure;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final int cameraIndex;
  final Offset? focusPoint;
  final bool isProcessing;

  const CameraSettingsState({
    this.filter = 'none',
    this.aspectRatio = 3 / 4,
    this.whiteFrame = false,
    this.geocamOn = true,
    this.autoRotate = true,
    this.torchOn = false,
    this.torchSupported = true,
    this.showGrid = true,
    this.showExposureSlider = false,
    this.exposureOffset = 0.0,
    this.minExposure = -2.0,
    this.maxExposure = 2.0,
    this.zoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 5.0,
    this.cameraIndex = 0,
    this.focusPoint,
    this.isProcessing = false,
  });

  CameraSettingsState copyWith({
    String? filter,
    double? aspectRatio,
    bool? whiteFrame,
    bool? geocamOn,
    bool? autoRotate,
    bool? torchOn,
    bool? torchSupported,
    bool? showGrid,
    bool? showExposureSlider,
    double? exposureOffset,
    double? minExposure,
    double? maxExposure,
    double? zoom,
    double? minZoom,
    double? maxZoom,
    int? cameraIndex,
    Offset? focusPoint,
    bool clearFocusPoint = false,
    bool? isProcessing,
  }) {
    return CameraSettingsState(
      filter: filter ?? this.filter,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      whiteFrame: whiteFrame ?? this.whiteFrame,
      geocamOn: geocamOn ?? this.geocamOn,
      autoRotate: autoRotate ?? this.autoRotate,
      torchOn: torchOn ?? this.torchOn,
      torchSupported: torchSupported ?? this.torchSupported,
      showGrid: showGrid ?? this.showGrid,
      showExposureSlider: showExposureSlider ?? this.showExposureSlider,
      exposureOffset: exposureOffset ?? this.exposureOffset,
      minExposure: minExposure ?? this.minExposure,
      maxExposure: maxExposure ?? this.maxExposure,
      zoom: zoom ?? this.zoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      cameraIndex: cameraIndex ?? this.cameraIndex,
      focusPoint: clearFocusPoint ? null : (focusPoint ?? this.focusPoint),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
