import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  bool ready = false;
  bool processing = false;
  String filter = 'none';
  int cameraIndex = 0;
  double zoom = 1.0;
  double aspectRatio = 3 / 4;
  bool whiteFrame = false;
  bool geocamOn = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await controller.initialize();
    if (mounted) setState(() => ready = true);
  }

  Future<void> _switchCamera() async {
    setState(() => ready = false);
    await controller.dispose();
    cameraIndex = (cameraIndex + 1) % cameras.length;
    await _initializeCamera();
  }

  @override
  void dispose() {
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
              child: CameraPreview(controller),
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
                                : filter == 'sepia'
                                ? 'invert'
                                : filter == 'invert'
                                ? 'blur'
                                : 'none';
                          });
                        },
                      ),

                      // Zoom
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                zoom = (zoom + 0.1).clamp(1.0, 5.0);
                                controller.setZoomLevel(zoom);
                              });
                            },
                          ),
                          Text(
                            '${zoom.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.zoom_out,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                zoom = (zoom - 0.1).clamp(1.0, 5.0);
                                controller.setZoomLevel(zoom);
                              });
                            },
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

//// IMAGE PROCESS

Uint8List processImage(Map<String, dynamic> data) {
  final Uint8List bytes = data['bytes'];
  final String filter = data['filter'];
  final bool whiteFrame = data['whiteFrame'];

  img.Image image = img.decodeImage(bytes)!;

  // Apply filter
  if (filter == 'mono') {
    image = img.grayscale(image);
  } else if (filter == 'vintage') {
    image = img.adjustColor(
      image,
      brightness: 0.1,
      contrast: 1.2,
      saturation: 0.7,
    );
    image = img.colorOffset(image, red: 15, green: 5, blue: -10);
    image = img.sepia(image);
  } else if (filter == 'sepia') {
    image = img.sepia(image);
  } else if (filter == 'invert') {
    image = img.invert(image);
  } else if (filter == 'blur') {
    image = img.gaussianBlur(image, radius: 2);
  }

  // Add white frame
  if (whiteFrame) {
    final frameWidth = (image.width * 0.05).toInt();
    final newWidth = image.width + frameWidth * 2;
    final newHeight = image.height + frameWidth * 2;
    final framed = img.Image(width: newWidth, height: newHeight);
    img.fill(framed, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(framed, image, dstX: frameWidth, dstY: frameWidth);
    image = framed;
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

//// WATERMARK

Future<Uint8List> addWatermark({
  required Uint8List imageBytes,
  required String location,
  required String address,
  required String latLng,
  required String dateTime,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final uiImage = await decodeImageFromList(imageBytes);
  final w = uiImage.width.toDouble();
  final h = uiImage.height.toDouble();

  canvas.drawImage(uiImage, Offset.zero, Paint());

  final overlayH = h * 0.22;
  final overlayTop = h - overlayH;

  canvas.drawRect(
    Rect.fromLTWH(0, overlayTop, w, overlayH),
    Paint()..color = const Color(0xE6000000),
  );

  final titleSize = h * 0.045;
  final bodySize = h * 0.032;
  final metaSize = h * 0.028;

  double y = overlayTop + overlayH * 0.18;
  final left = w * 0.08;

  draw(canvas, location, titleSize, FontWeight.w600, left, y, w);
  y += titleSize * 1.2;
  draw(canvas, address, bodySize, FontWeight.normal, left, y, w);
  y += bodySize * 1.15;
  draw(canvas, latLng, metaSize, FontWeight.normal, left, y, w);
  y += metaSize * 1.1;
  draw(canvas, dateTime, metaSize, FontWeight.normal, left, y, w);

  final pic = recorder.endRecording();
  final imgOut = await pic.toImage(uiImage.width, uiImage.height);
  final bd = await imgOut.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}

void draw(
  Canvas canvas,
  String text,
  double size,
  FontWeight weight,
  double x,
  double y,
  double w,
) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: Colors.white, fontSize: size, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.84);

  tp.paint(canvas, Offset(x, y));
}

//// SAVE (FIXED)

const MethodChannel _mediaChannel = MethodChannel('media_store');

Future<void> saveToGallery(Uint8List bytes) async {
  await _mediaChannel.invokeMethod('saveImage', {
    'bytes': bytes,
    'name': 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
  });
}

String formatDateTime() {
  final n = DateTime.now();
  final o = n.timeZoneOffset;
  final s = o.isNegative ? '-' : '+';
  return "${n.day.toString().padLeft(2, '0')}/"
      "${n.month.toString().padLeft(2, '0')}/"
      "${n.year} "
      "${n.hour.toString().padLeft(2, '0')}:"
      "${n.minute.toString().padLeft(2, '0')} "
      "GMT $s${o.inHours.abs()}:"
      "${(o.inMinutes.abs() % 60).toString().padLeft(2, '0')}";
}
