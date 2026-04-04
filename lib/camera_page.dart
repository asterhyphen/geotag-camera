import 'dart:async';
import 'dart:ui' as ui;
import 'services.dart';
import 'image_processing.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'main.dart';

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

class _GridOverlay extends StatelessWidget {
  final double aspectRatio;
  const _GridOverlay({required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridPainter()));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    // vertical lines
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(
      Offset(thirdW * 2, 0),
      Offset(thirdW * 2, size.height),
      paint,
    );

    // horizontal lines
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

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
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
  _LocationStamp? customLocation;
  late AnimationController _zoomAnim;
  double minZoom = 1.0;
  double maxZoom = 5.0;

  @override
  void initState() {
    super.initState();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _initializeCamera();
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

  VoidCallback? _zoomListener;

  VoidCallback _zoomListenerFactory(double start, double end) {
    void listener() {
      zoom = ui.lerpDouble(start, end, _zoomAnim.value)!;
      controller.setZoomLevel(zoom);
      if (mounted) setState(() {});
    }

    _zoomListener = listener;
    return listener;
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

    zoom = 1.0.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(zoom);
    await _syncCaptureOrientation();

    if (mounted) setState(() => ready = true);
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

  @override
  void dispose() {
    _zoomTimer?.cancel();
    _zoomAnim.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    if (processing || !controller.value.isInitialized) return;

    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    setState(() => processing = true);

    try {
      final XFile file = await controller.takePicture();
      final Uint8List originalBytes = await file.readAsBytes();
      final locationStamp = await _resolveLocationStamp();
      if (locationStamp == null) {
        return;
      }

      final dateTime = formatDateTime();

      unawaited(() async {
        final processed = await compute(processImage, {
          'bytes': originalBytes,
          'filter': filter,
          'whiteFrame': whiteFrame,
          'aspectRatio': aspectRatio,
          'autoRotate': autoRotate,
        });

        Uint8List finalImage = processed;
        if (geocamOn) {
          final watermarked = await addWatermark(
            imageBytes: processed,
            location: locationStamp.location,
            address: locationStamp.address,
            latLng: locationStamp.latLng,
            dateTime: dateTime,
          );
          finalImage = watermarked;
        }

        await saveToGallery(finalImage);
      }());
    } finally {
      setState(() => processing = false);
    }
  }

  Future<_LocationStamp?> _resolveLocationStamp() async {
    if (customLocation != null) return customLocation;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    final p = placemarks.first;

    return _LocationStamp(
      location: "${p.locality}, ${p.administrativeArea}, ${p.country}",
      address: "${p.street}, ${p.subLocality}",
      latLng:
          "Lat ${pos.latitude.toStringAsFixed(6)}, "
          "Long ${pos.longitude.toStringAsFixed(6)}",
    );
  }

  Future<void> _openLocationPicker() async {
    final locationController = TextEditingController(
      text: customLocation?.location ?? '',
    );
    final addressController = TextEditingController(
      text: customLocation?.address ?? '',
    );
    final latController = TextEditingController(
      text: _extractCoordinate(customLocation?.latLng, 'Lat'),
    );
    final lngController = TextEditingController(
      text: _extractCoordinate(customLocation?.latLng, 'Long'),
    );

    try {
      final pickedLocation = await showDialog<_LocationStamp?>(
        context: context,
        builder: (context) {
          String? errorText;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF111111),
                title: const Text(
                  'Pick Location',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _pickerFieldDecoration(
                          label: 'Location',
                          hint: 'City, State, Country',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _pickerFieldDecoration(
                          label: 'Address',
                          hint: 'Street, area',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: _pickerFieldDecoration(
                          label: 'Latitude',
                          hint: '12.345678',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: _pickerFieldDecoration(
                          label: 'Longitude',
                          hint: '77.123456',
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      const _LocationStamp(
                        location: '',
                        address: '',
                        latLng: '',
                      ),
                    ),
                    child: const Text('Use GPS'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final location = locationController.text.trim();
                      final address = addressController.text.trim();
                      final latitude = double.tryParse(latController.text.trim());
                      final longitude =
                          double.tryParse(lngController.text.trim());

                      if (location.isEmpty ||
                          address.isEmpty ||
                          latitude == null ||
                          longitude == null) {
                        setModalState(() {
                          errorText =
                              'Enter a location, address, latitude, and longitude.';
                        });
                        return;
                      }

                      Navigator.of(context).pop(
                        _LocationStamp(
                          location: location,
                          address: address,
                          latLng:
                              "Lat ${latitude.toStringAsFixed(6)}, "
                              "Long ${longitude.toStringAsFixed(6)}",
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || pickedLocation == null) return;

      HapticFeedback.selectionClick();
      setState(() {
        customLocation = pickedLocation.location.isEmpty ? null : pickedLocation;
      });
    } finally {
      locationController.dispose();
      addressController.dispose();
      latController.dispose();
      lngController.dispose();
    }
  }

  InputDecoration _pickerFieldDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(12),
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

  Timer? _zoomTimer;

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

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // CAMERA PREVIEW
          AspectRatio(
            aspectRatio: aspectRatio,
            child: GestureDetector(
              onDoubleTap: _switchCamera,

              onScaleUpdate: (details) {
                final newZoom = (zoom * details.scale).clamp(minZoom, maxZoom);

                controller.setZoomLevel(newZoom);
                setState(() => zoom = newZoom);
              },

              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  _GridOverlay(aspectRatio: aspectRatio),
                ],
              ),
            ),
          ),

          // CONTROLS
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: filter name and toggles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filter.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              letterSpacing: 1.5,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            cameras[cameraIndex].lensDirection ==
                                    CameraLensDirection.front
                                ? 'SELFIE'
                                : 'REAR',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            customLocation == null ? 'GPS' : 'CUSTOM LOCATION',
                            style: TextStyle(
                              color: customLocation == null
                                  ? Colors.white38
                                  : Colors.orangeAccent,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              whiteFrame
                                  ? Icons.border_all
                                  : Icons.border_clear,
                              color: whiteFrame ? Colors.blue : Colors.white70,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => whiteFrame = !whiteFrame);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              geocamOn ? Icons.location_on : Icons.location_off,
                              color: geocamOn ? Colors.green : Colors.white70,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => geocamOn = !geocamOn);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              customLocation == null
                                  ? Icons.edit_location_alt
                                  : Icons.place,
                              color: customLocation == null
                                  ? Colors.white70
                                  : Colors.orangeAccent,
                            ),
                            tooltip: customLocation == null
                                ? 'Pick location'
                                : 'Edit custom location',
                            onPressed: _openLocationPicker,
                          ),
                          IconButton(
                            icon: Icon(
                              autoRotate
                                  ? Icons.screen_rotation
                                  : Icons.screen_lock_rotation,
                              color: autoRotate
                                  ? Colors.orangeAccent
                                  : Colors.white70,
                            ),
                            tooltip: autoRotate
                                ? 'Auto rotate on'
                                : 'Auto rotate off',
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              setState(() => autoRotate = !autoRotate);
                              await _syncCaptureOrientation();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Shutter button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: capture,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                      if (processing)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                    ],
                  ),

                  // Bottom controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera switch
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _switchCamera();
                        },
                      ),

                      // Aspect ratio
                      PopupMenuButton<double>(
                        icon: const Icon(
                          Icons.aspect_ratio,
                          color: Colors.white,
                        ),
                        onSelected: (value) {
                          setState(() => aspectRatio = value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 1.0, child: Text('1:1')),
                          const PopupMenuItem(value: 4 / 3, child: Text('4:3')),
                          const PopupMenuItem(value: 3 / 4, child: Text('3:4')),
                          const PopupMenuItem(
                            value: 16 / 9,
                            child: Text('16:9'),
                          ),
                        ],
                      ),

                      // Filter
                      IconButton(
                        icon: const Icon(Icons.filter_alt, color: Colors.white),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            filter = filter == 'none'
                                ? 'mono'
                                : filter == 'mono'
                                ? 'vintage'
                                : filter == 'vintage'
                                ? 'sepia'
                                : 'none';
                          });
                        },
                      ),

                      // Zoom
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _applyZoom(zoom + 0.1);
                            },
                            onLongPress: () {
                              HapticFeedback.selectionClick();
                              _startContinuousZoom(0.05);
                            },
                            onLongPressUp: _stopContinuousZoom,
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${zoom.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 4),

                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _applyZoom(zoom - 0.1);
                            },
                            onLongPress: () {
                              HapticFeedback.selectionClick();
                              _startContinuousZoom(-0.05);
                            },
                            onLongPressUp: _stopContinuousZoom,
                            child: const Icon(
                              Icons.zoom_out,
                              color: Colors.white,
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
        ],
      ),
    );
  }
}
