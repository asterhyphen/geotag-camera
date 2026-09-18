import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'cute_widgets.dart';
import 'image_processing.dart';
import 'main.dart';
import 'pastel_theme.dart';
import 'services.dart';

class _LocationStamp {
  const _LocationStamp({
    required this.location,
    required this.address,
    required this.latLng,
  });

  final String location;
  final String address;
  final String latLng;
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CuteGridOverlay extends StatelessWidget {
  const _CuteGridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CuteGridPainter(),
      ),
    );
  }
}

class _CuteGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.lavender.withValues(alpha: 0.28)
      ..strokeWidth = 0.8;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    // Vertical lines
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(
      Offset(thirdW * 2, 0),
      Offset(thirdW * 2, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(
      Offset(0, thirdH * 2),
      Offset(size.width, thirdH * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _VintageFilmFrameOverlay extends StatelessWidget {
  final String filterName;

  const _VintageFilmFrameOverlay({
    required this.filterName,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Corner ticks & rangefinder reticle
          CustomPaint(
            painter: _VintageFramePainter(),
          ),
          // Top Vintage Markings Bar
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: PastelColors.butter.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 10,
                            color: PastelColors.butter,
                          ),
                          Text(
                            '24A',
                            style: TextStyle(
                              color: PastelColors.butter,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '35mm FILM',
                      style: TextStyle(
                        color: PastelColors.textLight.withValues(alpha: 0.65),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: PastelColors.lavender.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'ISO 400 • ${filterName.toUpperCase()}',
                    style: TextStyle(
                      color: PastelColors.peach.withValues(alpha: 0.95),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Vintage Markings
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'GEOCAM 1:1.8/35mm',
                style: TextStyle(
                  color: PastelColors.lavender,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VintageFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PastelColors.butter.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;
    const cornerLen = 14.0;
    const inset = 14.0;

    // Top-left
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + cornerLen, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset, inset + cornerLen), paint);

    // Top-right
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset - cornerLen, inset), paint);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, inset + cornerLen), paint);

    // Bottom-left
    canvas.drawLine(Offset(inset, h - inset), Offset(inset + cornerLen, h - inset), paint);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset, h - inset - cornerLen), paint);

    // Bottom-right
    canvas.drawLine(Offset(w - inset, h - inset), Offset(w - inset - cornerLen, h - inset), paint);
    canvas.drawLine(Offset(w - inset, h - inset), Offset(w - inset, h - inset - cornerLen), paint);

    // Center crosshair
    final centerPaint = Paint()
      ..color = PastelColors.lavender.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = w / 2;
    final cy = h / 2;
    const crossLen = 6.0;
    canvas.drawLine(Offset(cx - crossLen, cy), Offset(cx + crossLen, cy), centerPaint);
    canvas.drawLine(Offset(cx, cy - crossLen), Offset(cx, cy + crossLen), centerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CameraPageState extends State<CameraPage>
    with TickerProviderStateMixin {
  late CameraController controller;
  bool ready = false;
  bool processing = false;
  String filter = 'none';
  int cameraIndex = 0;
  double zoom = 1.0;
  double aspectRatio = 3 / 4;
  bool whiteFrame = false;
  bool geocamOn = true;
  bool autoRotate = true;
  bool torchOn = false;
  bool torchSupported = true;
  bool showGrid = true;
  _LocationStamp? customLocation;
  _LocationStamp? _cachedLocationStamp;
  StreamSubscription<Position>? _positionSub;

  double minExposure = -2.0;
  double maxExposure = 2.0;
  double exposureOffset = 0.0;
  bool showExposureSlider = false;
  Offset? focusPoint;
  Timer? _focusTimer;

  late AnimationController _zoomAnim;
  late AnimationController _flashAnim;
  double minZoom = 1.0;
  double maxZoom = 5.0;
  double _pinchStartZoom = 1.0;
  Timer? _zoomTimer;
  VoidCallback? _zoomListener;

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
    _initLocationService();
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _positionSub?.cancel();
    _zoomTimer?.cancel();
    _zoomAnim.dispose();
    _flashAnim.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Check last known position immediately for instant warmup (0ms)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        await _updateLocationFromPosition(lastPos);
      }

      // Query current location in background
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).then(_updateLocationFromPosition).catchError((_) {});

      // Keep location updated via stream as device moves
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 25,
        ),
      ).listen(_updateLocationFromPosition);
    } catch (e) {
      debugPrint('[GeoCam Location Service Error] $e');
    }
  }

  Future<void> _updateLocationFromPosition(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks.first : null;

      final city = p?.locality ?? p?.subAdministrativeArea ?? '';
      final region = p?.administrativeArea ?? '';
      final country = p?.country ?? '';

      final locationParts = [city, region, country].where((s) => s.isNotEmpty).toList();
      final locationStr = locationParts.isNotEmpty
          ? locationParts.join(', ')
          : "Lat ${pos.latitude.toStringAsFixed(4)}, Long ${pos.longitude.toStringAsFixed(4)}";

      final street = p?.street ?? '';
      final subLocality = p?.subLocality ?? '';
      final addressParts = [street, subLocality].where((s) => s.isNotEmpty).toList();
      final addressStr = addressParts.join(', ');

      final stamp = _LocationStamp(
        location: locationStr,
        address: addressStr,
        latLng:
            "Lat ${pos.latitude.toStringAsFixed(6)}, "
            "Long ${pos.longitude.toStringAsFixed(6)}",
      );

      if (mounted) {
        setState(() => _cachedLocationStamp = stamp);
      } else {
        _cachedLocationStamp = stamp;
      }
    } catch (_) {
      final fallbackStamp = _LocationStamp(
        location: "Lat ${pos.latitude.toStringAsFixed(4)}, Long ${pos.longitude.toStringAsFixed(4)}",
        address: "",
        latLng:
            "Lat ${pos.latitude.toStringAsFixed(6)}, "
            "Long ${pos.longitude.toStringAsFixed(6)}",
      );
      if (mounted) {
        setState(() => _cachedLocationStamp = fallbackStamp);
      } else {
        _cachedLocationStamp = fallbackStamp;
      }
    }
  }

  Future<void> _initializeCamera() async {
    controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await controller.initialize();
    minZoom = await controller.getMinZoomLevel();
    maxZoom = await controller.getMaxZoomLevel();

    try {
      minExposure = await controller.getMinExposureOffset();
      maxExposure = await controller.getMaxExposureOffset();
      exposureOffset = 0.0.clamp(minExposure, maxExposure);
      await controller.setExposureOffset(exposureOffset);
    } catch (_) {}

    zoom = 1.0.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(zoom);
    await _syncCaptureOrientation();
    await _syncTorchState();

    if (mounted) setState(() => ready = true);
  }

  Future<void> _onTapToFocus(TapUpDetails details, Size viewSize) async {
    if (!controller.value.isInitialized) return;

    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    setState(() {
      focusPoint = Offset(x, y);
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          focusPoint = null;
        });
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
    final clamped = value.clamp(minExposure, maxExposure);
    try {
      await controller.setExposureOffset(clamped);
      setState(() {
        exposureOffset = clamped;
      });
    } catch (_) {}
  }

  void _applyZoom(double target) {
    final start = zoom;
    final end = target.clamp(minZoom, maxZoom);

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
      zoom = ui.lerpDouble(start, end, _zoomAnim.value)!;
      controller.setZoomLevel(zoom);
      if (mounted) setState(() {});
    }

    _zoomListener = listener;
    return listener;
  }

  void _startContinuousZoom(double delta) {
    _zoomTimer ??= Timer.periodic(const Duration(milliseconds: 60), (_) async {
      zoom = (zoom + delta).clamp(minZoom, maxZoom);
      await controller.setZoomLevel(zoom);
      if (mounted) setState(() {});
    });
  }

  void _stopContinuousZoom() {
    _zoomTimer?.cancel();
    _zoomTimer = null;
  }

  Future<void> _syncCaptureOrientation() async {
    if (!controller.value.isInitialized) return;

    if (autoRotate) {
      await controller.unlockCaptureOrientation();
      return;
    }

    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }

  Future<void> _switchCamera() async {
    HapticFeedback.mediumImpact();
    setState(() => ready = false);
    _zoomTimer?.cancel();
    _zoomAnim.stop();
    await controller.dispose();

    cameraIndex = (cameraIndex + 1) % cameras.length;

    await _initializeCamera();

    zoom = 1.0.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(zoom);

    if (mounted) setState(() {});
  }

  Future<void> _syncTorchState() async {
    if (!controller.value.isInitialized) return;

    final wantsTorch =
        torchOn &&
        cameras[cameraIndex].lensDirection == CameraLensDirection.back;

    try {
      await controller.setFlashMode(
        wantsTorch ? FlashMode.torch : FlashMode.off,
      );
      torchSupported = true;
      if (!wantsTorch && torchOn) {
        torchOn = false;
      }
    } on CameraException {
      torchSupported = false;
      torchOn = false;
    }
  }

  Future<void> _toggleTorch() async {
    if (!controller.value.isInitialized) return;

    final isRearCamera =
        cameras[cameraIndex].lensDirection == CameraLensDirection.back;
    if (!isRearCamera) {
      if (!mounted) return;
      _showAlert('Flashlight is only available on the rear camera', variant: VintageAlertVariant.warning, icon: Icons.flashlight_off_rounded);
      return;
    }

    final nextTorchState = !torchOn;

    try {
      await controller.setFlashMode(
        nextTorchState ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        torchOn = nextTorchState;
        torchSupported = true;
      });
    } on CameraException {
      if (!mounted) return;
      setState(() {
        torchOn = false;
        torchSupported = false;
      });
      _showAlert('This camera does not support flashlight control', variant: VintageAlertVariant.warning, icon: Icons.warning_amber_rounded);
    }
  }

  void _showAlert(
    String message, {
    VintageAlertVariant variant = VintageAlertVariant.info,
    IconData? icon,
  }) {
    if (!mounted) return;
    showVintageAlert(
      context,
      message: message,
      variant: variant,
      icon: icon,
    );
  }

  Future<void> capture() async {
    if (processing || !controller.value.isInitialized) return;

    final captureWatch = Stopwatch()..start();
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // Trigger visual capture flash
    _flashAnim.forward(from: 0.0).then((_) => _flashAnim.reverse());

    setState(() => processing = true);

    try {
      final XFile file = await controller.takePicture();
      final shutterLag = captureWatch.elapsedMilliseconds;
      debugPrint(
        '[GeoCam Benchmark] Shutter tap -> Hardware takePicture completed in ${shutterLag}ms',
      );

      // Instant 0ms location retrieval from cached memory
      final locationStamp = customLocation ??
          _cachedLocationStamp ??
          const _LocationStamp(
            location: '',
            address: '',
            latLng: '',
          );

      final dateTime = formatDateTime();

      // Snapshot current camera settings
      final currentFilter = filter;
      final currentAspectRatio = aspectRatio;
      final currentWhiteFrame = whiteFrame;
      final currentAutoRotate = autoRotate;
      final currentGeocamOn = geocamOn;
      final filePath = file.path;

      // UNBLOCK UI IMMEDIATELY! Viewfinder and Shutter are responsive for the next shot
      if (mounted) {
        setState(() => processing = false);
      }

      // Background asynchronous zero-copy native processing
      unawaited(() async {
        final bgWatch = Stopwatch()..start();
        final success = await processAndSaveImageNative(
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
          _showAlert('Photo saved to gallery', variant: VintageAlertVariant.success, icon: Icons.photo_library_rounded);
        } else {
          // Fallback to Dart pipeline if native failed
          try {
            final bytes = await File(filePath).readAsBytes();
            final processed = await compute(processImage, {
              'bytes': bytes,
              'filter': currentFilter,
              'whiteFrame': currentWhiteFrame,
              'aspectRatio': currentAspectRatio,
              'autoRotate': currentAutoRotate,
            });

            Uint8List finalImage = processed;
            if (currentGeocamOn && locationStamp.location.isNotEmpty) {
              finalImage = await addWatermark(
                imageBytes: processed,
                location: locationStamp.location,
                address: locationStamp.address,
                latLng: locationStamp.latLng,
                dateTime: dateTime,
              );
            }
            await saveToGallery(finalImage);
            _showAlert('Photo saved to gallery', variant: VintageAlertVariant.success, icon: Icons.photo_library_rounded);
          } catch (e) {
            debugPrint('[GeoCam Fallback Error] $e');
            _showAlert('Failed to save photo: $e', variant: VintageAlertVariant.error);
          }
        }

        bgWatch.stop();
        debugPrint(
          '[GeoCam Benchmark] Total background processing & save completed in ${bgWatch.elapsedMilliseconds}ms',
        );
      }());
    } catch (e) {
      debugPrint('[GeoCam Capture Error] $e');
      if (mounted) {
        setState(() => processing = false);
        _showAlert('Capture failed: $e', variant: VintageAlertVariant.error);
      }
    }
  }

  Future<void> _openLocationPicker() async {
    final locationController = TextEditingController(
      text: customLocation?.location ?? _cachedLocationStamp?.location ?? '',
    );
    final addressController = TextEditingController(
      text: customLocation?.address ?? _cachedLocationStamp?.address ?? '',
    );
    final latController = TextEditingController(
      text: _extractCoordinate(
        customLocation?.latLng ?? _cachedLocationStamp?.latLng,
        'Lat',
      ),
    );
    final lngController = TextEditingController(
      text: _extractCoordinate(
        customLocation?.latLng ?? _cachedLocationStamp?.latLng,
        'Long',
      ),
    );

    try {
      final pickedLocation = await showDialog<_LocationStamp?>(
        context: context,
        builder: (context) {
          String? statusText;
          bool isSuccess = false;
          bool isDetecting = false;

          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> autoDetectCoordinates() async {
                final query = [
                  addressController.text.trim(),
                  locationController.text.trim(),
                ].where((s) => s.isNotEmpty).join(', ');

                if (query.isEmpty) {
                  setModalState(() {
                    statusText = 'Please enter a City or Address first to detect coordinates!';
                    isSuccess = false;
                  });
                  return;
                }

                setModalState(() {
                  isDetecting = true;
                  statusText = 'Finding coordinates for "$query"...';
                  isSuccess = false;
                });

                try {
                  final locations = await locationFromAddress(query);
                  if (locations.isNotEmpty) {
                    final loc = locations.first;
                    latController.text = loc.latitude.toStringAsFixed(6);
                    lngController.text = loc.longitude.toStringAsFixed(6);
                    setModalState(() {
                      isDetecting = false;
                      statusText = 'Coordinates auto-detected successfully!';
                      isSuccess = true;
                    });
                    HapticFeedback.selectionClick();
                    return;
                  }
                } catch (_) {}

                // Fallback: try using current GPS if query lookup failed
                try {
                  final currentPos = _cachedLocationStamp != null
                      ? null
                      : await Geolocator.getLastKnownPosition();
                  final lat = _extractCoordinate(_cachedLocationStamp?.latLng, 'Lat');
                  final lng = _extractCoordinate(_cachedLocationStamp?.latLng, 'Long');

                  if (lat.isNotEmpty && lng.isNotEmpty) {
                    latController.text = lat;
                    lngController.text = lng;
                    setModalState(() {
                      isDetecting = false;
                      statusText = 'Filled with your current GPS coordinates';
                      isSuccess = true;
                    });
                    return;
                  } else if (currentPos != null) {
                    latController.text = currentPos.latitude.toStringAsFixed(6);
                    lngController.text = currentPos.longitude.toStringAsFixed(6);
                    setModalState(() {
                      isDetecting = false;
                      statusText = 'Filled with your current GPS coordinates';
                      isSuccess = true;
                    });
                    return;
                  }
                } catch (_) {}

                setModalState(() {
                  isDetecting = false;
                  statusText = 'Could not find coordinates for this location. You can enter them manually.';
                  isSuccess = false;
                });
              }

              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: PastelColors.surfaceDark,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: PastelColors.pink.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: PastelShadows.soft(
                      color: PastelColors.pink.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cute Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PastelColors.pink.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: PastelColors.pink,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Location Tag',
                              style: TextStyle(
                                color: PastelColors.textLight,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        _buildCuteTextField(
                          controller: locationController,
                          label: 'City & Region',
                          hint: 'Tokyo, Japan',
                          icon: Icons.location_city_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildCuteTextField(
                          controller: addressController,
                          label: 'Address / Landmark',
                          hint: 'Shibuya Crossing',
                          icon: Icons.map_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Autodetect Coordinates Button Row
                        Row(
                          children: [
                            Expanded(
                              child: BouncyTap(
                                onTap: isDetecting ? null : autoDetectCoordinates,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PastelColors.lavender.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: PastelColors.lavender.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isDetecting) ...[
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              PastelColors.lavender,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ] else ...[
                                        const Icon(
                                          Icons.auto_fix_high_rounded,
                                          size: 15,
                                          color: PastelColors.lavender,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      const Text(
                                        'Auto-Detect Lat/Long',
                                        style: TextStyle(
                                          color: PastelColors.lavender,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildCuteTextField(
                                controller: latController,
                                label: 'Latitude',
                                hint: '35.6595',
                                isNumeric: true,
                                icon: Icons.explore_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCuteTextField(
                                controller: lngController,
                                label: 'Longitude',
                                hint: '139.7004',
                                isNumeric: true,
                                icon: Icons.compass_calibration_rounded,
                              ),
                            ),
                          ],
                        ),

                        if (statusText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            statusText!,
                            style: TextStyle(
                              color: isSuccess ? PastelColors.mint : PastelColors.pinkDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(
                                const _LocationStamp(
                                  location: '',
                                  address: '',
                                  latLng: '',
                                ),
                              ),
                              icon: const Icon(
                                Icons.gps_fixed_rounded,
                                size: 16,
                                color: PastelColors.mint,
                              ),
                              label: const Text(
                                'Use GPS',
                                style: TextStyle(
                                  color: PastelColors.mint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: PastelColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                BouncyTap(
                                  onTap: () async {
                                    var location = locationController.text.trim();
                                    var address = addressController.text.trim();
                                    var latStr = latController.text.trim();
                                    var lngStr = lngController.text.trim();

                                    // If empty, auto-fill from cached or current GPS
                                    if (location.isEmpty && address.isEmpty) {
                                      setModalState(() {
                                        statusText = 'Please provide a location name or address!';
                                        isSuccess = false;
                                      });
                                      return;
                                    }

                                    double? latitude = double.tryParse(latStr);
                                    double? longitude = double.tryParse(lngStr);

                                    // If coordinates missing, attempt quick lookup or fallback to cached GPS
                                    if (latitude == null || longitude == null) {
                                      final query = [address, location].where((s) => s.isNotEmpty).join(', ');
                                      try {
                                        final locs = await locationFromAddress(query);
                                        if (locs.isNotEmpty) {
                                          latitude = locs.first.latitude;
                                          longitude = locs.first.longitude;
                                        }
                                      } catch (_) {}
                                    }

                                    // Fallback to cached device GPS if available
                                    if (latitude == null || longitude == null) {
                                      final latCached = double.tryParse(_extractCoordinate(_cachedLocationStamp?.latLng, 'Lat'));
                                      final lngCached = double.tryParse(_extractCoordinate(_cachedLocationStamp?.latLng, 'Long'));
                                      if (latCached != null && lngCached != null) {
                                        latitude = latCached;
                                        longitude = lngCached;
                                      } else {
                                        latitude = 0.0;
                                        longitude = 0.0;
                                      }
                                    }

                                    final latLngStr = (latitude != 0.0 || longitude != 0.0)
                                        ? "Lat ${latitude.toStringAsFixed(6)}, Long ${longitude.toStringAsFixed(6)}"
                                        : "";

                                    Navigator.of(context).pop(
                                      _LocationStamp(
                                        location: location.isNotEmpty ? location : address,
                                        address: address,
                                        latLng: latLngStr,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: PastelColors.magicGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: PastelColors.pink
                                              .withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Save Tag',
                                      style: TextStyle(
                                        color: PastelColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted || pickedLocation == null) return;

      HapticFeedback.selectionClick();
      setState(() {
        customLocation =
            pickedLocation.location.isEmpty ? null : pickedLocation;
      });
    } finally {
      locationController.dispose();
      addressController.dispose();
      latController.dispose();
      lngController.dispose();
    }
  }

  Widget _buildCuteTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            )
          : TextInputType.text,
      style: const TextStyle(
        color: PastelColors.textLight,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: PastelColors.lavender, size: 18)
            : null,
        filled: true,
        fillColor: PastelColors.cardDark.withValues(alpha: 0.8),
        hintStyle: const TextStyle(
          color: PastelColors.textMuted,
          fontSize: 12,
        ),
        labelStyle: const TextStyle(
          color: PastelColors.lavender,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: PastelColors.lavender.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: PastelColors.pink,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _extractCoordinate(String? latLng, String prefix) {
    if (latLng == null || latLng.isEmpty) return '';
    final parts = latLng.split(', ');
    for (final part in parts) {
      if (part.startsWith('$prefix ')) {
        return part.substring(prefix.length + 1);
      }
    }
    return '';
  }

  void _showAspectRatioSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final ratios = [
          {'label': '3:4', 'sub': 'Portrait', 'ratio': 3 / 4, 'icon': Icons.crop_portrait_rounded},
          {'label': '1:1', 'sub': 'Square', 'ratio': 1.0, 'icon': Icons.crop_square_rounded},
          {'label': '9:16', 'sub': 'Full', 'ratio': 9 / 16, 'icon': Icons.stay_current_portrait_rounded},
          {'label': '4:3', 'sub': 'Classic', 'ratio': 4 / 3, 'icon': Icons.crop_landscape_rounded},
          {'label': '16:9', 'sub': 'Cinema', 'ratio': 16 / 9, 'icon': Icons.crop_16_9_rounded},
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PastelColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: PastelColors.lavender.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PastelColors.lavender.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aspect Ratio',
                style: TextStyle(
                  color: PastelColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ratios.map((item) {
                  final double r = item['ratio'] as double;
                  final isSelected = (aspectRatio - r).abs() < 0.05;

                  return BouncyTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => aspectRatio = r);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PastelColors.pink.withValues(alpha: 0.25)
                            : PastelColors.cardDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? PastelColors.pink
                              : PastelColors.lavender.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? PastelColors.pink
                                : PastelColors.textMuted,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? PastelColors.pink
                                  : PastelColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            item['sub'] as String,
                            style: const TextStyle(
                              color: PastelColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getAspectRatioLabel() {
    if ((aspectRatio - 1.0).abs() < 0.05) return '1:1';
    if ((aspectRatio - (3 / 4)).abs() < 0.05) return '3:4';
    if ((aspectRatio - (9 / 16)).abs() < 0.05) return '9:16';
    if ((aspectRatio - (4 / 3)).abs() < 0.05) return '4:3';
    if ((aspectRatio - (16 / 9)).abs() < 0.05) return '16:9';
    return '3:4';
  }

  Widget _buildCameraPreviewWidget() {
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

  @override
  Widget build(BuildContext context) {
    if (!ready) {
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

    final isFrontCamera =
        cameras[cameraIndex].lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: PastelColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // TOP FLOATING CONTROL ISLAND
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      onPressed: _toggleTorch,
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
                        setState(() => showExposureSlider = !showExposureSlider);
                      },
                    ),

                    // Grid Toggle
                    CuteIconButton(
                      icon: showGrid
                          ? Icons.grid_on_rounded
                          : Icons.grid_off_rounded,
                      isActive: showGrid,
                      activeColor: PastelColors.sky,
                      tooltip: showGrid ? 'Grid On' : 'Grid Off',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => showGrid = !showGrid);
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
                        setState(() => whiteFrame = !whiteFrame);
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
                        setState(() => geocamOn = !geocamOn);
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
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        setState(() => autoRotate = !autoRotate);
                        await _syncCaptureOrientation();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // STATUS RIBBON (Location & Lens Info)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location Status Pill (Tap to edit custom location)
                  Flexible(
                    child: CuteBadge(
                      icon: customLocation != null
                          ? Icons.edit_location_alt_rounded
                          : (_cachedLocationStamp != null
                              ? Icons.location_on_rounded
                              : Icons.gps_fixed_rounded),
                      label: customLocation != null
                          ? customLocation!.location
                          : (_cachedLocationStamp != null &&
                                  _cachedLocationStamp!.location.isNotEmpty
                              ? _cachedLocationStamp!.location
                              : 'GPS Auto'),
                      color: customLocation != null
                          ? PastelColors.peachDeep
                          : PastelColors.mint,
                      onTap: _openLocationPicker,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Exposure EV Badge (Quick toggle)
                      CuteBadge(
                        icon: Icons.wb_sunny_rounded,
                        label: '${exposureOffset >= 0 ? '+' : ''}${exposureOffset.toStringAsFixed(1)} EV',
                        color: showExposureSlider ? PastelColors.butter : PastelColors.lavender,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => showExposureSlider = !showExposureSlider);
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
                        label: _getAspectRatioLabel(),
                        color: PastelColors.sky,
                        onTap: _showAspectRatioSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exposure Slider if open
            if (showExposureSlider) ...[
              const SizedBox(height: 6),
              VintageExposureSlider(
                value: exposureOffset,
                min: minExposure,
                max: maxExposure,
                onChanged: _setExposure,
                onClose: () => setState(() => showExposureSlider = false),
              ),
            ],

            const SizedBox(height: 4),

            // 📷 CAMERA VIEWFINDER (SQUIRCLE FRAMED)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: PastelColors.lavender.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PastelColors.lavender.withValues(alpha: 0.2),
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
                              onDoubleTap: _switchCamera,
                              onTapUp: (details) => _onTapToFocus(details, viewSize),
                              onScaleStart: (_) {
                                _pinchStartZoom = zoom;
                              },
                              onScaleUpdate: (details) {
                                final adjustedScale =
                                    1 + ((details.scale - 1) * 0.3);
                                final newZoom =
                                    (_pinchStartZoom * adjustedScale).clamp(
                                  minZoom,
                                  maxZoom,
                                );
                                controller.setZoomLevel(newZoom);
                                setState(() => zoom = newZoom);
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildCameraPreviewWidget(),
                                  if (showGrid) const _CuteGridOverlay(),

                                  // Vintage 35mm Film Frame Overlay
                                  _VintageFilmFrameOverlay(
                                    filterName: filter,
                                  ),

                                  // Focus Reticle Ring
                                  if (focusPoint != null)
                                    VintageFocusRing(
                                      position: focusPoint!,
                                      exposureOffset: exposureOffset,
                                    ),

                              // Capture Flash Effect
                              AnimatedBuilder(
                                animation: _flashAnim,
                                builder: (context, child) {
                                  if (_flashAnim.value == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    color: PastelColors.pinkLight.withValues(
                                      alpha: _flashAnim.value * 0.85,
                                    ),
                                  );
                                },
                              ),

                              // Viewfinder watermark indicator if enabled
                              if (geocamOn)
                                Positioned(
                                  bottom: 10,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.stars_rounded,
                                          size: 11,
                                          color: PastelColors.pink,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'GEOCAM ON',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 🔍 ZOOM BAR
            Center(
              child: CuteZoomBar(
                currentZoom: zoom,
                minZoom: minZoom,
                maxZoom: maxZoom,
                onZoomChanged: _applyZoom,
                onStartContinuousIn: () => _startContinuousZoom(0.05),
                onStartContinuousOut: () => _startContinuousZoom(-0.05),
                onStopContinuous: _stopContinuousZoom,
              ),
            ),

            const SizedBox(height: 10),

            // 🎨 CUTE FILTER SELECTOR
            CuteFilterSelector(
              currentFilter: filter,
              onFilterSelected: (newFilter) {
                setState(() => filter = newFilter);
              },
            ),

            const SizedBox(height: 14),

            // 🌸 BOTTOM CONTROLS DECK
            Padding(
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
                    onPressed: _showAspectRatioSheet,
                  ),

                  // Big Cute Shutter Button
                  CuteShutterButton(
                    onTap: capture,
                    processing: processing,
                    size: 82,
                  ),

                  // Flip Camera Button
                  CuteIconButton(
                    icon: Icons.flip_camera_ios_rounded,
                    size: 52,
                    iconSize: 24,
                    activeColor: PastelColors.lavender,
                    tooltip: 'Flip Camera',
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
