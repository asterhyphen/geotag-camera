import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/camera_settings_state.dart';

class CameraSettingsNotifier extends StateNotifier<CameraSettingsState> {
  CameraSettingsNotifier() : super(const CameraSettingsState());

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setAspectRatio(double ratio) {
    state = state.copyWith(aspectRatio: ratio);
  }

  void toggleWhiteFrame() {
    state = state.copyWith(whiteFrame: !state.whiteFrame);
  }

  void toggleGeocam() {
    state = state.copyWith(geocamOn: !state.geocamOn);
  }

  void toggleAutoRotate() {
    state = state.copyWith(autoRotate: !state.autoRotate);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void toggleExposureSlider() {
    state = state.copyWith(showExposureSlider: !state.showExposureSlider);
  }

  void hideExposureSlider() {
    state = state.copyWith(showExposureSlider: false);
  }

  void setExposureOffset(double offset) {
    final clamped = offset.clamp(state.minExposure, state.maxExposure);
    state = state.copyWith(exposureOffset: clamped);
  }

  void setExposureLimits(double min, double max) {
    state = state.copyWith(minExposure: min, maxExposure: max);
  }

  void setZoom(double zoom) {
    final clamped = zoom.clamp(state.minZoom, state.maxZoom);
    state = state.copyWith(zoom: clamped);
  }

  void setZoomLimits(double min, double max) {
    state = state.copyWith(minZoom: min, maxZoom: max);
  }

  void setTorch(bool torch) {
    state = state.copyWith(torchOn: torch);
  }

  void setTorchSupported(bool supported) {
    state = state.copyWith(torchSupported: supported);
  }

  void setCameraIndex(int index) {
    state = state.copyWith(cameraIndex: index);
  }

  void setFocusPoint(Offset? point) {
    if (point == null) {
      state = state.copyWith(clearFocusPoint: true);
    } else {
      state = state.copyWith(focusPoint: point);
    }
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }
}

final cameraSettingsProvider =
    StateNotifierProvider<CameraSettingsNotifier, CameraSettingsState>((ref) {
  return CameraSettingsNotifier();
});
