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
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    // vertical lines
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(
        Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), paint);

    // horizontal lines
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(
        Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), paint);
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

  _zoomAnim.removeListener(_zoomListener);

  _zoomAnim.addListener(_zoomListenerFactory(start, end));
  _zoomAnim.forward();
}

late VoidCallback _zoomListener;

VoidCallback _zoomListenerFactory(double start, double end) {
  _zoomListener = () {
    zoom = ui.lerpDouble(start, end, _zoomAnim.value)!;
    controller.setZoomLevel(zoom);
    if (mounted) setState(() {});
  };
  return _zoomListener;
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

    if (mounted) setState(() => ready = true);
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

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => processing = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.first;

      final location = "${p.locality}, ${p.administrativeArea}, ${p.country}";
      final address = "${p.street}, ${p.subLocality}";
      final latLng =
          "Lat ${pos.latitude.toStringAsFixed(6)}, "
          "Long ${pos.longitude.toStringAsFixed(6)}";
      final dateTime = formatDateTime();

      unawaited(() async {
        final processed = await compute(processImage, {
          'bytes': originalBytes,
          'filter': filter,
          'whiteFrame': whiteFrame,
          'aspectRatio': aspectRatio,
        });

        Uint8List finalImage = processed;
        if (geocamOn) {
          final watermarked = await addWatermark(
            imageBytes: processed,
            location: location,
            address: address,
            latLng: latLng,
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
  Timer? _zoomTimer;

void _startContinuousZoom(double delta) {
  _zoomTimer ??= Timer.periodic(
    const Duration(milliseconds: 60),
    (_) async {
      zoom = (zoom + delta).clamp(minZoom, maxZoom);
      await controller.setZoomLevel(zoom);
      if (mounted) setState(() {});
    },
  );
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
)

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