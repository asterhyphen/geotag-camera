import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;

const MethodChannel _mediaChannel = MethodChannel('media_store');

void main() {
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
  final picker = ImagePicker();

  bool busy = false;
  bool includeMap = false; // reserved for future
  String filter = 'none';

  Future<void> capture() async {
    if (busy) return;
    setState(() => busy = true);

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (photo == null) {
        setState(() => busy = false);
        return;
      }

      final originalBytes = await photo.readAsBytes();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => busy = false);
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

      // ---- FILTERS IN ISOLATE ----
      final cleanBytes = await compute(processImage, {
        'bytes': originalBytes,
        'filter': filter,
      });

      final ts = DateTime.now().millisecondsSinceEpoch;

      // ---- SAVE CLEAN IMAGE IMMEDIATELY ----
      await saveToGallery(cleanBytes, "IMG_$ts.jpg");

      // UI FREE IMMEDIATELY
      setState(() => busy = false);

      // ---- BACKGROUND WATERMARK (NON-BLOCKING) ----
      unawaited(() async {
        final watermarked = await addWatermark(
          imageBytes: cleanBytes,
          location: location,
          address: address,
          latLng: latLng,
          dateTime: dateTime,
        );

        await saveToGallery(watermarked, "IMG_${ts}_geo.jpg");
      }());
    } catch (_) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // SHUTTER BUTTON
          Center(
            child: busy
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
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

          // CONTROLS
          Positioned(
            bottom: 28,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // MAP ICON (placeholder, now responsive)
                IconButton(
                  icon: Icon(
                    includeMap ? Icons.map : Icons.map_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => includeMap = !includeMap),
                ),

                // FILTER ICON (CYCLE)
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      filter = filter == 'none'
                          ? 'mono'
                          : filter == 'mono'
                          ? 'vintage'
                          : 'none';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//// ================= MEDIASTORE =================

Future<void> saveToGallery(Uint8List bytes, String name) async {
  await _mediaChannel.invokeMethod('saveImage', {'bytes': bytes, 'name': name});
}

//// ================= FILTERS =================

Uint8List processImage(Map<String, dynamic> data) {
  final Uint8List bytes = data['bytes'];
  final String filter = data['filter'];

  img.Image image = img.decodeImage(bytes)!;

  switch (filter) {
    case 'mono':
      image = img.grayscale(image);
      break;

    case 'vintage':
      image = img.adjustColor(
        image,
        brightness: 0.02,
        contrast: 1.1,
        saturation: 0.85,
      );
      image = img.colorOffset(image, red: 8, green: 4, blue: -8);
      break;

    case 'none':
    default:
      break;
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

//// ================= WATERMARK =================

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

  final textLeft = w * 0.08;
  double y = overlayTop + overlayH * 0.18;

  _draw(
    canvas,
    location,
    TextStyle(
      color: Colors.white,
      fontSize: titleSize,
      fontWeight: FontWeight.w600,
    ),
    textLeft,
    y,
    w * 0.84,
  );
  y += titleSize * 1.2;

  _draw(
    canvas,
    address,
    TextStyle(color: Colors.white70, fontSize: bodySize),
    textLeft,
    y,
    w * 0.84,
  );
  y += bodySize * 1.15;

  _draw(
    canvas,
    latLng,
    TextStyle(color: Colors.white60, fontSize: metaSize),
    textLeft,
    y,
    w * 0.84,
  );
  y += metaSize * 1.1;

  _draw(
    canvas,
    dateTime,
    TextStyle(color: Colors.white60, fontSize: metaSize),
    textLeft,
    y,
    w * 0.84,
  );

  final picture = recorder.endRecording();
  final imgOut = await picture.toImage(uiImage.width, uiImage.height);
  final bd = await imgOut.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}

void _draw(
  Canvas canvas,
  String text,
  TextStyle style,
  double x,
  double y,
  double maxWidth,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  tp.paint(canvas, Offset(x, y));
}

//// ================= UTILS =================

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
