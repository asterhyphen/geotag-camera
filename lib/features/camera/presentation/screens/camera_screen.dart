import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/pastel_theme.dart';
import '../../../../core/widgets/cute_filter_selector.dart';
import '../../../../core/widgets/cute_zoom_bar.dart';
import '../../../../core/widgets/vintage_alert.dart';
import '../../../../core/widgets/vintage_exposure_slider.dart';
import '../../../location/presentation/dialogs/location_picker_dialog.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../watermark/data/services/dart_image_service.dart';
import '../../../watermark/data/services/date_time_formatter.dart';
import '../../../watermark/data/services/native_image_service.dart';
import '../providers/camera_controller_provider.dart';
import '../providers/camera_settings_provider.dart';
import '../widgets/aspect_ratio_sheet.dart';
import '../widgets/bottom_controls_deck.dart';
import '../widgets/camera_viewfinder.dart';
import '../widgets/status_ribbon.dart';
import '../widgets/top_control_bar.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  late CameraController controller;
  bool _ready = false;
  Timer? _focusTimer;
  Timer? _zoomTimer;
  late AnimationController _zoomAnim;
  late AnimationController _flashAnim;
  VoidCallback? _zoomListener;

  final NativeImageService _nativeImageService = const NativeImageService();

  @override
  void initState() {
    super.initState();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _flashAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _zoomTimer?.cancel();
    _zoomAnim.dispose();
    _flashAnim.dispose();
    if (_ready) {
      controller.dispose();
    }
    super.dispose();
  }

  List<CameraDescription> get _cameras => ref.read(availableCamerasProvider);

  Future<void> _initializeCamera() async {
    final settings = ref.read(cameraSettingsProvider);
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);

    if (_cameras.isEmpty) return;

    controller = CameraController(
      _cameras[settings.cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );

    await controller.initialize();
    final minZ = await controller.getMinZoomLevel();
    final maxZ = await controller.getMaxZoomLevel();
    settingsNotifier.setZoomLimits(minZ, maxZ);

    try {
      final minExp = await controller.getMinExposureOffset();
      final maxExp = await controller.getMaxExposureOffset();
      settingsNotifier.setExposureLimits(minExp, maxExp);
      final clampedExp = 0.0.clamp(minExp, maxExp);
      settingsNotifier.setExposureOffset(clampedExp);
      await controller.setExposureOffset(clampedExp);
    } catch (_) {}

    final defaultZoom = 1.0.clamp(minZ, maxZ);
    settingsNotifier.setZoom(defaultZoom);
    await controller.setZoomLevel(defaultZoom);

    await _syncCaptureOrientation();
    await _syncTorchState();

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  Future<void> _onTapToFocus(TapUpDetails details, Size viewSize) async {
    if (!controller.value.isInitialized) return;

    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);
    settingsNotifier.setFocusPoint(Offset(x, y));

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        settingsNotifier.setFocusPoint(null);
      }
    });

    try {
      final nx = (x / viewSize.width).clamp(0.0, 1.0);
      final ny = (y / viewSize.height).clamp(0.0, 1.0);
      await controller.setFocusPoint(Offset(nx, ny));
      await controller.setExposurePoint(Offset(nx, ny));
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _setExposure(double value) async {
    if (!controller.value.isInitialized) return;
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);
    final settings = ref.read(cameraSettingsProvider);
    final clamped = value.clamp(settings.minExposure, settings.maxExposure);

    try {
      await controller.setExposureOffset(clamped);
      settingsNotifier.setExposureOffset(clamped);
    } catch (_) {}
  }

  void _applyZoom(double target) {
    final settings = ref.read(cameraSettingsProvider);
    final start = settings.zoom;
    final end = target.clamp(settings.minZoom, settings.maxZoom);

    _zoomAnim.stop();
    _zoomAnim.reset();
    if (_zoomListener != null) {
      _zoomAnim.removeListener(_zoomListener!);
    }

    _zoomAnim.addListener(_zoomListenerFactory(start, end));
    _zoomAnim.forward();
  }

  VoidCallback _zoomListenerFactory(double start, double end) {
    void listener() {
      final newZoom = ui.lerpDouble(start, end, _zoomAnim.value)!;
      controller.setZoomLevel(newZoom);
      ref.read(cameraSettingsProvider.notifier).setZoom(newZoom);
    }

    _zoomListener = listener;
    return listener;
  }

  void _startContinuousZoom(double delta) {
    _zoomTimer ??= Timer.periodic(const Duration(milliseconds: 60), (_) async {
      final settings = ref.read(cameraSettingsProvider);
      final newZoom = (settings.zoom + delta).clamp(
        settings.minZoom,
        settings.maxZoom,
      );
      await controller.setZoomLevel(newZoom);
      ref.read(cameraSettingsProvider.notifier).setZoom(newZoom);
    });
  }

  void _stopContinuousZoom() {
    _zoomTimer?.cancel();
    _zoomTimer = null;
  }

  Future<void> _syncCaptureOrientation() async {
    if (!controller.value.isInitialized) return;
    final autoRotate = ref.read(cameraSettingsProvider).autoRotate;

    if (autoRotate) {
      await controller.unlockCaptureOrientation();
      return;
    }

    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    HapticFeedback.mediumImpact();
    setState(() => _ready = false);
    _zoomTimer?.cancel();
    _zoomAnim.stop();
    await controller.dispose();

    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);
    final currentIdx = ref.read(cameraSettingsProvider).cameraIndex;
    final nextIdx = (currentIdx + 1) % _cameras.length;
    settingsNotifier.setCameraIndex(nextIdx);

    await _initializeCamera();
  }

  Future<void> _syncTorchState() async {
    if (!controller.value.isInitialized) return;
    final settings = ref.read(cameraSettingsProvider);
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);

    final wantsTorch =
        settings.torchOn &&
        _cameras[settings.cameraIndex].lensDirection ==
            CameraLensDirection.back;

    try {
      await controller.setFlashMode(
        wantsTorch ? FlashMode.torch : FlashMode.off,
      );
      settingsNotifier.setTorchSupported(true);
      if (!wantsTorch && settings.torchOn) {
        settingsNotifier.setTorch(false);
      }
    } on CameraException {
      settingsNotifier.setTorchSupported(false);
      settingsNotifier.setTorch(false);
    }
  }

  Future<void> _toggleTorch() async {
    if (!controller.value.isInitialized) return;
    final settings = ref.read(cameraSettingsProvider);
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);

    final isRearCamera =
        _cameras[settings.cameraIndex].lensDirection ==
        CameraLensDirection.back;

    if (!isRearCamera) {
      if (!mounted) return;
      _showAlert(
        'Flashlight is only available on the rear camera',
        variant: VintageAlertVariant.warning,
        icon: Icons.flashlight_off_rounded,
      );
      return;
    }

    final nextTorchState = !settings.torchOn;

    try {
      await controller.setFlashMode(
        nextTorchState ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      settingsNotifier.setTorch(nextTorchState);
      settingsNotifier.setTorchSupported(true);
    } on CameraException {
      if (!mounted) return;
      settingsNotifier.setTorch(false);
      settingsNotifier.setTorchSupported(false);
      _showAlert(
        'This camera does not support flashlight control',
        variant: VintageAlertVariant.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  void _showAlert(
    String message, {
    VintageAlertVariant variant = VintageAlertVariant.info,
    IconData? icon,
  }) {
    if (!mounted) return;
    showVintageAlert(context, message: message, variant: variant, icon: icon);
  }

  Future<void> _capture() async {
    final settings = ref.read(cameraSettingsProvider);
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);

    if (settings.isProcessing || !controller.value.isInitialized) return;

    final captureWatch = Stopwatch()..start();
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // Trigger visual capture flash
    _flashAnim.forward(from: 0.0).then((_) => _flashAnim.reverse());

    settingsNotifier.setProcessing(true);

    try {
      final XFile file = await controller.takePicture();
      final shutterLag = captureWatch.elapsedMilliseconds;
      debugPrint(
        '[GeoCam Benchmark] Shutter tap -> Hardware takePicture completed in ${shutterLag}ms',
      );

      // Instant 0ms location retrieval from cached memory
      final locationState = ref.read(locationProvider);
      final locationStamp = locationState.effectiveLocation;
      final dateTime = formatDateTime();

      // Snapshot current camera settings
      final currentFilter = settings.filter;
      final currentAspectRatio = settings.aspectRatio;
      final currentWhiteFrame = settings.whiteFrame;
      final currentAutoRotate = settings.autoRotate;
      final currentGeocamOn = settings.geocamOn;
      final filePath = file.path;

      // UNBLOCK UI IMMEDIATELY! Viewfinder and Shutter are responsive for the next shot
      settingsNotifier.setProcessing(false);

      // Background asynchronous zero-copy native processing
      unawaited(() async {
        final bgWatch = Stopwatch()..start();
        final success = await _nativeImageService.processAndSaveImageNative(
          inputPath: filePath,
          filter: currentFilter,
          aspectRatio: currentAspectRatio,
          whiteFrame: currentWhiteFrame,
          autoRotate: currentAutoRotate,
          geocamOn: currentGeocamOn,
          location: locationStamp.location,
          address: locationStamp.address,
          latLng: locationStamp.latLng,
          dateTime: dateTime,
        );

        if (success) {
          _showAlert(
            'Photo saved to gallery',
            variant: VintageAlertVariant.success,
            icon: Icons.photo_library_rounded,
          );
        } else {
          // Fallback to Dart pipeline if native failed
          try {
            final bytes = await File(filePath).readAsBytes();
            final processed = await compute(DartImageService.processImage, {
              'bytes': bytes,
              'filter': currentFilter,
              'whiteFrame': currentWhiteFrame,
              'aspectRatio': currentAspectRatio,
              'autoRotate': currentAutoRotate,
            });

            Uint8List finalImage = processed;
            if (currentGeocamOn && locationStamp.location.isNotEmpty) {
              finalImage = await DartImageService.addWatermark(
                imageBytes: processed,
                location: locationStamp.location,
                address: locationStamp.address,
                latLng: locationStamp.latLng,
                dateTime: dateTime,
              );
            }
            await _nativeImageService.saveToGallery(finalImage);
            _showAlert(
              'Photo saved to gallery',
              variant: VintageAlertVariant.success,
              icon: Icons.photo_library_rounded,
            );
          } catch (e) {
            debugPrint('[GeoCam Fallback Error] $e');
            _showAlert(
              'Failed to save photo: $e',
              variant: VintageAlertVariant.error,
            );
          }
        }

        bgWatch.stop();
        debugPrint(
          '[GeoCam Benchmark] Total background processing & save completed in ${bgWatch.elapsedMilliseconds}ms',
        );
      }());
    } catch (e) {
      debugPrint('[GeoCam Capture Error] $e');
      settingsNotifier.setProcessing(false);
      _showAlert('Capture failed: $e', variant: VintageAlertVariant.error);
    }
  }

  Future<void> _openLocationPicker() async {
    final locationState = ref.read(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

    final picked = await showLocationPickerDialog(
      context,
      currentCustomLocation: locationState.customLocation,
      cachedLocation: locationState.cachedLocationStamp,
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      locationNotifier.setCustomLocation(
        picked.location.isEmpty ? null : picked,
      );
    }
  }

  void _showAspectRatioSheetModal() {
    final currentRatio = ref.read(cameraSettingsProvider).aspectRatio;
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);

    showAspectRatioSheet(
      context: context,
      currentRatio: currentRatio,
      onRatioSelected: (ratio) {
        settingsNotifier.setAspectRatio(ratio);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: PastelColors.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PastelColors.magicGradient,
                  boxShadow: PastelShadows.glow(PastelColors.pink),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    PastelColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Starting Geocam...',
                style: TextStyle(
                  color: PastelColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final settings = ref.watch(cameraSettingsProvider);
    final settingsNotifier = ref.read(cameraSettingsProvider.notifier);
    final locationState = ref.watch(locationProvider);

    final isFrontCamera = _cameras.isNotEmpty &&
        _cameras[settings.cameraIndex].lensDirection ==
            CameraLensDirection.front;

    return Scaffold(
      backgroundColor: PastelColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // TOP FLOATING CONTROL ISLAND
            TopControlBar(
              torchOn: settings.torchOn,
              showExposureSlider: settings.showExposureSlider,
              showGrid: settings.showGrid,
              whiteFrame: settings.whiteFrame,
              geocamOn: settings.geocamOn,
              autoRotate: settings.autoRotate,
              onToggleTorch: _toggleTorch,
              onToggleExposureSlider: settingsNotifier.toggleExposureSlider,
              onToggleGrid: settingsNotifier.toggleGrid,
              onToggleWhiteFrame: settingsNotifier.toggleWhiteFrame,
              onToggleGeocam: settingsNotifier.toggleGeocam,
              onToggleAutoRotate: () async {
                settingsNotifier.toggleAutoRotate();
                await _syncCaptureOrientation();
              },
            ),

            // STATUS RIBBON (Location & Lens Info)
            StatusRibbon(
              customLocation: locationState.customLocation,
              cachedLocationStamp: locationState.cachedLocationStamp,
              exposureOffset: settings.exposureOffset,
              showExposureSlider: settings.showExposureSlider,
              isFrontCamera: isFrontCamera,
              aspectRatio: settings.aspectRatio,
              onOpenLocationPicker: _openLocationPicker,
              onToggleExposureSlider: settingsNotifier.toggleExposureSlider,
              onShowAspectRatioSheet: _showAspectRatioSheetModal,
            ),

            // Exposure Slider if open
            if (settings.showExposureSlider) ...[
              const SizedBox(height: 6),
              VintageExposureSlider(
                value: settings.exposureOffset,
                min: settings.minExposure,
                max: settings.maxExposure,
                onChanged: _setExposure,
                onClose: settingsNotifier.hideExposureSlider,
              ),
            ],

            const SizedBox(height: 4),

            // 📷 CAMERA VIEWFINDER (SQUIRCLE FRAMED)
            Expanded(
              child: CameraViewfinder(
                controller: controller,
                aspectRatio: settings.aspectRatio,
                filter: settings.filter,
                showGrid: settings.showGrid,
                geocamOn: settings.geocamOn,
                effectiveLocation: locationState.effectiveLocation,
                focusPoint: settings.focusPoint,
                exposureOffset: settings.exposureOffset,
                flashAnim: _flashAnim,
                zoom: settings.zoom,
                minZoom: settings.minZoom,
                maxZoom: settings.maxZoom,
                onSwitchCamera: _switchCamera,
                onTapToFocus: _onTapToFocus,
                onZoomUpdated: (newZoom) {
                  settingsNotifier.setZoom(newZoom);
                },
              ),
            ),

            const SizedBox(height: 8),

            // 🔍 ZOOM BAR
            Center(
              child: CuteZoomBar(
                currentZoom: settings.zoom,
                minZoom: settings.minZoom,
                maxZoom: settings.maxZoom,
                onZoomChanged: _applyZoom,
                onStartContinuousIn: () => _startContinuousZoom(0.05),
                onStartContinuousOut: () => _startContinuousZoom(-0.05),
                onStopContinuous: _stopContinuousZoom,
              ),
            ),

            const SizedBox(height: 10),

            // 🎨 CUTE FILTER SELECTOR
            CuteFilterSelector(
              currentFilter: settings.filter,
              onFilterSelected: settingsNotifier.setFilter,
            ),

            const SizedBox(height: 14),

            // 🌸 BOTTOM CONTROLS DECK
            BottomControlsDeck(
              onShowAspectRatioSheet: _showAspectRatioSheetModal,
              onCapture: _capture,
              onSwitchCamera: _switchCamera,
              isProcessing: settings.isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}
