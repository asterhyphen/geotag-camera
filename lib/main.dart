import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildPreview() {
    final size = MediaQuery.of(context).size;
    final scale =
        size.aspectRatio * controller.value.aspectRatio;

    return Transform.scale(
      scale: scale < 1 ? 1 / scale : scale,
      child: Center(child: CameraPreview(controller)),
    );
  }

  Future<void> playShutterSound() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> capture() async {
    if (processing || !controller.value.isInitialized) return;

    HapticFeedback.mediumImpact();
    playShutterSound();
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

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.first;

      final location =
          "${p.locality}, ${p.administrativeArea}, ${p.country}";
      final address = "${p.street}, ${p.subLocality}";
      final latLng =
          "Lat ${pos.latitude.toStringAsFixed(6)}, "
          "Long ${pos.longitude.toStringAsFixed(6)}";
      final dateTime = formatDateTime();

      unawaited(() async {
        final processed = await compute(processImage, {
          'bytes': originalBytes,
          'filter': filter,
        });

        final watermarked = await addWatermark(
          imageBytes: processed,
          location: location,
          address: address,
          latLng: latLng,
          dateTime: dateTime,
        );

        await saveToGallery(watermarked);
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
      body: Stack(
        children: [
          buildPreview(),

          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Text(
              filter.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.4,
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: capture,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            right: 32,
            child: IconButton(
              icon: const Icon(Icons.filter_alt, color: Colors.white),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  filter = filter == 'none'
                      ? 'mono'
                      : filter == 'mono'
                          ? 'vintage'
                          : 'none';
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List processImage(Map<String, dynamic> data) {
  final Uint8List bytes = data['bytes'];
  final String filter = data['filter'];

  img.Image image = img.decodeImage(bytes)!;

  if (filter == 'mono') {
    image = img.grayscale(image);
  } else if (filter == 'vintage') {
    image = img.adjustColor(
      image,
      brightness: 0.02,
      contrast: 1.1,
      saturation: 0.85,
    );
    image = img.colorOffset(image, red: 8, green: 4, blue: -8);
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

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

void draw(Canvas canvas, String text, double size, FontWeight weight,
    double x, double y, double w) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: weight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.84);

  tp.paint(canvas, Offset(x, y));
}

Future<void> saveToGallery(Uint8List bytes) async {
  final dir = await getExternalStorageDirectory();
  final folder = Directory('${dir!.path}/Pictures/GeoCam');
  if (!folder.existsSync()) folder.createSync(recursive: true);

  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File('${folder.path}/IMG_$ts.jpg');
  await file.writeAsBytes(bytes);

  await MethodChannel('media_scanner')
      .invokeMethod('scanFile', {'path': file.path});
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
